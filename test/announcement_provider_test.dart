import 'package:bhoardmate/models/announcement.dart';
import 'package:bhoardmate/providers/announcement_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_database_service.dart';

void main() {
  test('loads newest first and new posts arrive through the stream', () async {
    final provider = AnnouncementProvider(db: FakeDatabaseService());
    await provider.loadAnnouncements();
    expect(provider.isLoading, isFalse);
    expect(provider.announcements.first.title, 'Pest control');
    await provider.addAnnouncement(
      const Announcement(
        title: 'Meeting',
        message: 'House meeting in the lobby.',
        createdAt: '2026-10-24T18:00:00.000',
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(provider.announcements.first.title, 'Meeting');
    expect(provider.announcements.first.id, isNotNull);
    expect(provider.errorMessage, isNull);
  });

  test('clear forgets the list after logout', () async {
    final provider = AnnouncementProvider(db: FakeDatabaseService());
    await provider.loadAnnouncements();
    provider.clear();
    expect(provider.announcements, isEmpty);
  });

  test('a load still running at logout is ignored', () async {
    final db = FakeDatabaseService();
    final provider = AnnouncementProvider(db: db);
    final load = provider.loadAnnouncements();
    provider.clear();
    await load;
    expect(provider.announcements, isEmpty);
    expect(provider.isLoading, isFalse);
    // no listener was started, so new posts don't come back either
    await db.insertAnnouncement(
      const Announcement(
        title: 'Meeting',
        message: 'House meeting in the lobby.',
        createdAt: '2026-10-24T18:00:00.000',
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(provider.announcements, isEmpty);
  });

  test('a good snapshot after a stream error clears the error', () async {
    final db = FakeDatabaseService();
    final provider = AnnouncementProvider(db: db);
    await provider.loadAnnouncements();
    db.failAnnouncementsStream();
    await Future<void>.delayed(Duration.zero);
    expect(provider.errorMessage, isNotNull);
    await db.deleteAnnouncement('a1');
    await Future<void>.delayed(Duration.zero);
    expect(provider.errorMessage, isNull);
    expect(provider.announcements.length, 2);
  });
}
