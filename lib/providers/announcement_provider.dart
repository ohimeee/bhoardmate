import 'dart:async';

import 'package:flutter/foundation.dart';

import '../models/announcement.dart';
import '../services/database_service.dart';

// announcements from Firestore, newest first
class AnnouncementProvider extends ChangeNotifier {
  final DatabaseService _db;

  // the tests pass a fake service so they don't need Firebase
  AnnouncementProvider({DatabaseService? db}) : _db = db ?? DatabaseService();

  List<Announcement> _announcements = [];
  bool _isLoading = false;
  String? _errorMessage;
  StreamSubscription<List<Announcement>>? _sub;

  List<Announcement> get announcements => _announcements;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  // get the list once, then keep listening so a new announcement
  // from the owner shows up on every boarder's phone by itself
  Future<void> loadAnnouncements() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    try {
      _announcements = await _db.getAnnouncements();
      _sub?.cancel();
      _sub = _db.announcementsStream().listen(
        (list) {
          _announcements = list;
          notifyListeners();
        },
        onError: (e) {
          _errorMessage = 'Could not load announcements. Please try again.';
          notifyListeners();
        },
      );
    } catch (e) {
      _errorMessage = 'Could not load announcements. Please try again.';
    }
    _isLoading = false;
    notifyListeners();
  }

  // the stream updates the list, these only write to Firestore
  Future<void> addAnnouncement(Announcement announcement) async {
    try {
      await _db.insertAnnouncement(announcement);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Could not save the announcement. Please try again.';
    }
    notifyListeners();
  }

  Future<void> updateAnnouncement(Announcement announcement) async {
    try {
      await _db.updateAnnouncement(announcement);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Could not save the announcement. Please try again.';
    }
    notifyListeners();
  }

  Future<void> deleteAnnouncement(String id) async {
    try {
      await _db.deleteAnnouncement(id);
      _errorMessage = null;
    } catch (e) {
      _errorMessage = 'Could not remove the announcement. Please try again.';
    }
    notifyListeners();
  }

  // logout: stop listening and forget the old user's data
  void clear() {
    _sub?.cancel();
    _sub = null;
    _announcements = [];
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
