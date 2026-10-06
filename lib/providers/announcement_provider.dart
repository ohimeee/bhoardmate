import 'package:flutter/foundation.dart';

import '../models/announcement.dart';

// sample data for now, DatabaseService comes in #3
class AnnouncementProvider extends ChangeNotifier {
  final List<Announcement> _all = [
    const Announcement(
      id: 1,
      title: 'Water interruption',
      message:
          'No water on October 12 from 8 AM to 3 PM because of pipe repairs. Please store water ahead.',
      eventDate: '2026-10-12',
      createdAt: '2026-10-03T09:00:00.000',
    ),
    const Announcement(
      id: 2,
      title: 'Electricity rate increase',
      message:
          'The electricity rate goes up to 12 pesos per kWh this month. Please use appliances wisely.',
      createdAt: '2026-10-05T14:30:00.000',
    ),
    const Announcement(
      id: 3,
      title: 'Pest control',
      message:
          'Pest control for all rooms on October 20. Please keep food covered and be available that day.',
      eventDate: '2026-10-20',
      createdAt: '2026-10-06T10:15:00.000',
    ),
  ];

  List<Announcement> _announcements = [];
  final bool _isLoading = false;
  String? _errorMessage;

  List<Announcement> get announcements => _announcements;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int _nextId() {
    int max = 0;
    for (final a in _all) {
      if (a.id != null && a.id! > max) max = a.id!;
    }
    return max + 1;
  }

  // newest first
  void _refresh() {
    _announcements = [..._all]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    notifyListeners();
  }

  Future<void> loadAnnouncements() async {
    _errorMessage = null;
    _refresh();
  }

  Future<void> addAnnouncement(Announcement announcement) async {
    _all.add(
      Announcement(
        id: _nextId(),
        title: announcement.title,
        message: announcement.message,
        eventDate: announcement.eventDate,
        createdAt: announcement.createdAt,
      ),
    );
    _refresh();
  }

  Future<void> updateAnnouncement(Announcement announcement) async {
    final index = _all.indexWhere((a) => a.id == announcement.id);
    if (index == -1) {
      _errorMessage = 'Announcement not found';
      notifyListeners();
      return;
    }
    _all[index] = announcement;
    _refresh();
  }

  Future<void> deleteAnnouncement(int id) async {
    _all.removeWhere((a) => a.id == id);
    _refresh();
  }
}
