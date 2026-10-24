import 'package:bhoardmate/models/owner.dart';
import 'package:bhoardmate/providers/auth_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_database_service.dart';

void main() {
  test('wrong room code shows an error and stays logged out', () async {
    final auth = AuthProvider(db: FakeDatabaseService());
    final ok = await auth.loginBoarder('bh01-rm2', '9999');
    expect(ok, isFalse);
    expect(auth.isLoggedIn, isFalse);
    expect(auth.errorMessage, 'Wrong room ID or access code');
  });

  test('boarder login clears the error and hides access codes', () async {
    final auth = AuthProvider(db: FakeDatabaseService());
    await auth.loginBoarder('BH01-RM2', '9999');
    final ok = await auth.loginBoarder('bh01-rm2', '2222');
    expect(ok, isTrue);
    expect(auth.errorMessage, isNull);
    expect(auth.currentRoomId, 'BH01-RM2');
    expect(auth.rooms.length, 4);
    expect(auth.rooms.every((room) => room.accessCode == ''), isTrue);
    expect(auth.owner!.name, 'Mrs. Estoesta');
  });

  test('owner sees codes, wrong password shows an error', () async {
    final auth = AuthProvider(db: FakeDatabaseService());
    expect(await auth.loginOwner('owner@bhoardmate.app', 'wrong'), isFalse);
    expect(auth.errorMessage, 'Wrong email or password');
    expect(await auth.loginOwner('owner@bhoardmate.app', 'admin123'), isTrue);
    expect(auth.isOwner, isTrue);
    expect(auth.rooms.first.accessCode, '1111');
  });

  test('updateOwner saves name and contact, logout clears data', () async {
    final db = FakeDatabaseService();
    final auth = AuthProvider(db: db);
    await auth.loginOwner('owner@bhoardmate.app', 'admin123');
    final owner = auth.owner!;
    await auth.updateOwner(
      Owner(
        id: owner.id,
        name: 'New Name',
        email: owner.email,
        contactNumber: '09170000000',
      ),
    );
    expect(auth.owner!.name, 'New Name');
    expect(db.owner.contactNumber, '09170000000');
    await auth.logout();
    expect(auth.isLoggedIn, isFalse);
    expect(auth.rooms, isEmpty);
    expect(auth.owner, isNull);
  });
}
