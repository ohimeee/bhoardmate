import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/owner.dart';
import '../models/room.dart';
import '../services/database_service.dart';

// login, rooms and the owner's info. The data comes from DatabaseService
class AuthProvider extends ChangeNotifier {
  final DatabaseService _db;

  // the tests pass a fake service so they don't need Firebase
  AuthProvider({DatabaseService? db}) : _db = db ?? DatabaseService();

  List<Room> _rooms = [];
  // room id -> access code, only filled for the owner
  Map<String, String> _codes = {};
  Owner? _owner;
  bool _isLoggedIn = false;
  bool _isOwner = false;
  String? _currentRoomId;
  String? _errorMessage;

  // live updates from Firestore, cancelled on logout
  StreamSubscription<List<Room>>? _roomsSub;
  StreamSubscription<Owner?>? _ownerSub;

  List<Room> get rooms => _rooms;
  Owner? get owner => _owner;
  bool get isLoggedIn => _isLoggedIn;
  bool get isOwner => _isOwner;
  String? get currentRoomId => _currentRoomId;
  String? get errorMessage => _errorMessage;

  // Firebase remembers the account after the app is closed,
  // so this logs the user back in without the login screen
  Future<void> loadSession() async {
    if (_db.currentUid == null) return;
    try {
      if (await _db.isOwnerAccount()) {
        _isOwner = true;
        _currentRoomId = null;
      } else {
        final roomId = await _db.getSession();
        if (roomId == null) {
          await logout();
          return;
        }
        _isOwner = false;
        _currentRoomId = roomId;
      }
      await _startListening();
      _isLoggedIn = true;
      _errorMessage = null;
      notifyListeners();
    } catch (e) {
      if (_db.errorCode(e) == 'permission-denied') {
        // the owner reset this room's code, log in again
        await logout();
      } else {
        _errorMessage = _errorText(e);
        notifyListeners();
      }
    }
  }

  Future<bool> loginBoarder(String roomId, String code) async {
    final id = roomId.trim().toUpperCase();
    try {
      // firestore.rules check the code, wrong code = permission-denied
      await _db.signInBoarder(id, code.trim());
      _isOwner = false;
      _currentRoomId = id;
      await _startListening();
    } catch (e) {
      await logout();
      _errorMessage = _db.errorCode(e) == 'permission-denied'
          ? 'Wrong room ID or access code'
          : _errorText(e);
      notifyListeners();
      return false;
    }
    _isLoggedIn = true;
    _errorMessage = null;
    notifyListeners();
    return true;
  }

  Future<bool> loginOwner(String email, String password) async {
    try {
      await _db.signInOwner(email.trim(), password);
      // only the account with an owners/ doc is the owner
      if (!await _db.isOwnerAccount()) {
        await logout();
        _errorMessage = 'This account is not the owner';
        notifyListeners();
        return false;
      }
      _isOwner = true;
      _currentRoomId = null;
      await _startListening();
    } catch (e) {
      await logout();
      final code = _db.errorCode(e);
      _errorMessage =
          code == 'invalid-credential' ||
              code == 'wrong-password' ||
              code == 'user-not-found' ||
              code == 'invalid-email'
          ? 'Wrong email or password'
          : _errorText(e);
      notifyListeners();
      return false;
    }
    _isLoggedIn = true;
    _errorMessage = null;
    notifyListeners();
    return true;
  }

  Future<void> logout() async {
    await _roomsSub?.cancel();
    await _ownerSub?.cancel();
    _roomsSub = null;
    _ownerSub = null;
    await _db.signOut();
    _rooms = [];
    _codes = {};
    _owner = null;
    _isLoggedIn = false;
    _isOwner = false;
    _currentRoomId = null;
    _errorMessage = null;
    notifyListeners();
  }

  // get the data once, then keep listening so changes
  // made on another phone show up without a refresh
  Future<void> _startListening() async {
    await _loadRooms();
    _owner = await _db.getOwner();
    await _roomsSub?.cancel();
    _roomsSub = _db.roomsStream().listen(_setRooms, onError: _onStreamError);
    await _ownerSub?.cancel();
    _ownerSub = _db.ownerStream().listen((owner) {
      _owner = owner;
      notifyListeners();
    }, onError: _onStreamError);
  }

  // screens call this for Retry, it throws if loading fails
  Future<void> loadRooms() async {
    if (_db.currentUid == null) return;
    await _loadRooms();
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> _loadRooms() async {
    if (_isOwner) _codes = await _db.getAccessCodes();
    _setRooms(await _db.getRooms());
  }

  // rooms/ has no codes, the owner gets them from roomCodes/
  void _setRooms(List<Room> rooms) {
    _rooms = rooms
        .map((room) => room.copyWith(accessCode: _codes[room.id] ?? ''))
        .toList();
    notifyListeners();
  }

  // e.g. the owner reset this boarder's code, so the rules deny the reads
  void _onStreamError(Object e) {
    _errorMessage = _errorText(e);
    notifyListeners();
  }

  // the rooms stream updates the list, these only write to Firestore
  Future<void> addRoom(Room room) async {
    if (_rooms.any((r) => r.id == room.id)) {
      _errorMessage = 'Room ${room.id} already exists';
      notifyListeners();
      return;
    }
    try {
      await _db.insertRoom(room);
      _codes[room.id] = room.accessCode;
      _setRooms(_rooms);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = _errorText(e);
    }
    notifyListeners();
  }

  Future<void> updateRoom(Room room) async {
    try {
      await _db.updateRoom(room);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = _errorText(e);
    }
    notifyListeners();
  }

  // tenant moved out: new code, boarder info cleared, ID stays
  Future<void> resetAccessCode(String roomId, String newCode) async {
    try {
      await _db.resetAccessCode(roomId, newCode);
      _codes[roomId] = newCode;
      _setRooms(_rooms);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = _errorText(e);
    }
    notifyListeners();
  }

  // throws on failure so OwnerProfileScreen can show its error
  Future<void> updateOwner(Owner owner) async {
    try {
      await _db.updateOwner(owner);
    } catch (e) {
      _errorMessage = _errorText(e);
      notifyListeners();
      rethrow;
    }
    _owner = owner;
    _errorMessage = null;
    notifyListeners();
  }

  // Firebase error code -> short message for the screens
  String _errorText(Object e) {
    final code = _db.errorCode(e);
    if (code == 'unavailable' || code == 'network-request-failed') {
      return 'No internet connection. Please try again.';
    }
    if (code == 'permission-denied') {
      return 'You are not allowed to do that. Please log in again.';
    }
    return 'Something went wrong. Please try again.';
  }

  @override
  void dispose() {
    _roomsSub?.cancel();
    _ownerSub?.cancel();
    super.dispose();
  }
}
