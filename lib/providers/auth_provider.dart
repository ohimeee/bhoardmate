import 'package:flutter/foundation.dart';

import '../models/owner.dart';
import '../models/room.dart';

// sample data for now, DatabaseService comes in #3
class AuthProvider extends ChangeNotifier {
  final Owner _owner = const Owner(
    id: 1,
    name: 'Mrs. Estoesta',
    username: 'owner',
    password: 'admin123',
    contactNumber: '0917 123 4567',
  );

  List<Room> _rooms = [
    const Room(
      id: 'BH01-RM1',
      accessCode: '1111',
      monthlyRent: 2500,
      boarderName: 'Maria Santos',
      contactNumber: '0918 222 3344',
      age: 21,
      emergencyContactName: 'Elena Santos',
      emergencyContactNumber: '0918 555 1020',
    ),
    const Room(
      id: 'BH01-RM2',
      accessCode: '2222',
      monthlyRent: 2500,
      boarderName: 'Juan Dela Cruz',
      contactNumber: '0917 333 4455',
      age: 20,
      emergencyContactName: 'Pedro Dela Cruz',
      emergencyContactNumber: '0917 666 7788',
    ),
    const Room(
      id: 'BH01-RM3',
      accessCode: '3333',
      monthlyRent: 2500,
      boarderName: 'Angelo Reyes',
      contactNumber: '0926 444 5566',
      age: 22,
      emergencyContactName: 'Liza Reyes',
      emergencyContactNumber: '0926 777 8899',
    ),
    // vacant room
    const Room(id: 'BH01-RM4', accessCode: '4444', monthlyRent: 2500),
  ];

  bool _isLoggedIn = false;
  bool _isOwner = false;
  String? _currentRoomId;
  String? _errorMessage;

  List<Room> get rooms => _rooms;
  Owner get owner => _owner;
  bool get isLoggedIn => _isLoggedIn;
  bool get isOwner => _isOwner;
  String? get currentRoomId => _currentRoomId;
  String? get errorMessage => _errorMessage;

  Future<void> loadSession() async {
    // no saved session yet, shared_preferences comes in #5
  }

  Future<bool> loginBoarder(String roomId, String code) async {
    final id = roomId.trim().toUpperCase();
    final matches = _rooms.where(
      (r) => r.id == id && r.accessCode == code.trim(),
    );
    if (matches.isEmpty) {
      _errorMessage = 'Wrong room ID or access code';
      notifyListeners();
      return false;
    }
    _isLoggedIn = true;
    _isOwner = false;
    _currentRoomId = id;
    _errorMessage = null;
    notifyListeners();
    return true;
  }

  Future<bool> loginOwner(String username, String password) async {
    if (username.trim() != _owner.username || password != _owner.password) {
      _errorMessage = 'Wrong username or password';
      notifyListeners();
      return false;
    }
    _isLoggedIn = true;
    _isOwner = true;
    _currentRoomId = null;
    _errorMessage = null;
    notifyListeners();
    return true;
  }

  void logout() {
    _isLoggedIn = false;
    _isOwner = false;
    _currentRoomId = null;
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> loadRooms() async {
    notifyListeners();
  }

  Future<void> addRoom(Room room) async {
    if (_rooms.any((r) => r.id == room.id)) {
      _errorMessage = 'Room ${room.id} already exists';
      notifyListeners();
      return;
    }
    _rooms = [..._rooms, room];
    _errorMessage = null;
    notifyListeners();
  }

  Future<void> updateRoom(Room room) async {
    _rooms = _rooms.map((r) => r.id == room.id ? room : r).toList();
    notifyListeners();
  }

  // tenant moved out: new code, boarder info cleared, ID stays
  Future<void> resetAccessCode(String roomId, String newCode) async {
    _rooms = _rooms.map((r) {
      if (r.id != roomId) return r;
      return Room(id: r.id, accessCode: newCode, monthlyRent: r.monthlyRent);
    }).toList();
    notifyListeners();
  }
}
