import 'package:bhoardmate/models/concern.dart';
import 'package:bhoardmate/providers/concern_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_database_service.dart';

void main() {
  test('boarder only gets their own room, newest first', () async {
    final provider = ConcernProvider(db: FakeDatabaseService());
    await provider.loadConcerns(roomId: 'BH01-RM2');
    expect(provider.concerns.length, 1);
    await provider.addConcern(
      const Concern(
        roomId: 'BH01-RM2',
        title: 'Broken fan',
        description: 'Fan will not turn on.',
        createdAt: '2026-10-24T18:00:00.000',
      ),
    );
    await Future<void>.delayed(Duration.zero);
    expect(provider.concerns.length, 2);
    expect(provider.concerns.first.title, 'Broken fan');
    expect(provider.concerns.every((c) => c.roomId == 'BH01-RM2'), isTrue);
  });

  test('owner toggles status and deletes', () async {
    final provider = ConcernProvider(db: FakeDatabaseService());
    await provider.loadConcerns();
    expect(provider.concerns.length, 3);
    await provider.toggleStatus('c1');
    await Future<void>.delayed(Duration.zero);
    expect(provider.concerns.firstWhere((c) => c.id == 'c1').status, 'done');
    await provider.deleteConcern('c1');
    await Future<void>.delayed(Duration.zero);
    expect(provider.concerns.any((c) => c.id == 'c1'), isFalse);
    provider.clear();
    expect(provider.concerns, isEmpty);
  });

  test('a load still running at logout is ignored', () async {
    final provider = ConcernProvider(db: FakeDatabaseService());
    final load = provider.loadConcerns(roomId: 'BH01-RM2');
    provider.clear();
    await load;
    expect(provider.concerns, isEmpty);
    expect(provider.isLoading, isFalse);
  });

  test('a good snapshot after a stream error clears the error', () async {
    final db = FakeDatabaseService();
    final provider = ConcernProvider(db: db);
    await provider.loadConcerns();
    db.failConcernsStream();
    await Future<void>.delayed(Duration.zero);
    expect(provider.errorMessage, isNotNull);
    await db.deleteConcern('c2');
    await Future<void>.delayed(Duration.zero);
    expect(provider.errorMessage, isNull);
    expect(provider.concerns.length, 2);
  });
}
