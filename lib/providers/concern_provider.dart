import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/concern.dart';
import '../services/database_service.dart';

// boarder concerns from Firestore, newest first
class ConcernProvider extends ChangeNotifier {
  final DatabaseService _db;

  // the tests pass a fake service so they don't need Firebase
  ConcernProvider({DatabaseService? db}) : _db = db ?? DatabaseService();

  List<Concern> _concerns = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<Concern>>? _sub;
  // each load gets a number; clear() or a newer load makes the old one
  // stale so a slow answer can't bring back data after logout
  int _loadCount = 0;

  List<Concern> get concerns => _concerns;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // newest first, sorted here because Firestore would need an
  // extra index to sort and filter by roomId in one query
  void _setConcerns(List<Concern> list) {
    // a good snapshot after a stream error means it works again
    _errorMessage = null;
    _concerns = list..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  // owner: roomId null = every room.
  // boarder: only their room, the rules reject anything else
  Future<void> loadConcerns({String? roomId}) async {
    final load = ++_loadCount;
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      final list = await _db.getConcerns(roomId: roomId);
      if (load != _loadCount) return;
      _setConcerns(list);
      _sub?.cancel();
      _sub = _db
          .concernsStream(roomId: roomId)
          .listen(
            _setConcerns,
            onError: (e) {
              _errorMessage = 'Could not load concerns. Please try again.';
              notifyListeners();
            },
          );
    } catch (e) {
      if (load != _loadCount) return;
      _errorMessage = 'Could not load concerns. Please try again.';
    }
    _isLoading = false;
    notifyListeners();
  }

  // the stream updates the list, these only write to Firestore
  Future<void> addConcern(Concern concern) async {
    try {
      await _db.insertConcern(concern);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Could not report the concern. Please try again.';
    }
    notifyListeners();
  }

  // owner only: pending <-> done
  Future<void> toggleStatus(String id) async {
    final matches = _concerns.where((c) => c.id == id);
    if (matches.isEmpty) return;
    final concern = matches.first;
    try {
      await _db.updateConcern(
        concern.copyWith(
          status: concern.status == 'pending' ? 'done' : 'pending',
        ),
      );
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Could not save the change. Please try again.';
    }
    notifyListeners();
  }

  Future<void> deleteConcern(String id) async {
    try {
      await _db.deleteConcern(id);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Could not remove the concern. Please try again.';
    }
    notifyListeners();
  }

  // logout: stop listening and forget the old user's data
  void clear() {
    _loadCount++;
    _sub?.cancel();
    _sub = null;
    _isLoading = false;
    _concerns = [];
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
