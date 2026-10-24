import 'dart:async';

import 'package:bhoardmate/models/announcement.dart';
import 'package:bhoardmate/models/owner.dart';
import 'package:bhoardmate/models/room.dart';
import 'package:bhoardmate/services/database_service.dart';
import 'package:firebase_core/firebase_core.dart';

// DatabaseService with sample data in memory, so widget tests
// don't need Firebase. Same data as the seeded Firestore project
class FakeDatabaseService extends DatabaseService {
  Owner owner = const Owner(
    id: 'owner1',
    name: 'Mrs. Estoesta',
    email: 'owner@bhoardmate.app',
    contactNumber: '0917 123 4567',
  );

  List<Room> rooms = [
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

  List<Announcement> announcements = [
    const Announcement(
      id: 'a1',
      title: 'Water interruption',
      message:
          'No water on October 12 from 8 AM to 3 PM because of pipe repairs. Please store water ahead.',
      eventDate: '2026-10-12',
      createdAt: '2026-10-03T09:00:00.000',
    ),
    const Announcement(
      id: 'a2',
      title: 'Electricity rate increase',
      message:
          'The electricity rate goes up to 12 pesos per kWh this month. Please use appliances wisely.',
      createdAt: '2026-10-05T14:30:00.000',
    ),
    const Announcement(
      id: 'a3',
      title: 'Pest control',
      message:
          'Pest control for all rooms on October 20. Please keep food covered and be available that day.',
      eventDate: '2026-10-20',
      createdAt: '2026-10-06T10:15:00.000',
    ),
  ];

  // new documents get ids like x1, x2 (Firestore makes random ones)
  int _lastId = 0;

  String _newId() {
    _lastId++;
    return 'x$_lastId';
  }

  // test-only password, the real one is not in the repo
  final String password = 'admin123';

  final _roomsController = StreamController<List<Room>>.broadcast();
  final _ownerController = StreamController<Owner?>.broadcast();
  final _codesController = StreamController<Map<String, String>>.broadcast();
  final _announcementsController =
      StreamController<List<Announcement>>.broadcast();
  String? _uid;
  String? _roomId;

  @override
  String? get currentUid => _uid;

  @override
  Future<void> signInOwner(String email, String password) async {
    if (email != owner.email || password != this.password) {
      throw FirebaseException(plugin: 'auth', code: 'invalid-credential');
    }
    _uid = owner.id;
    _roomId = null;
  }

  @override
  Future<void> signInBoarder(String roomId, String accessCode) async {
    if (!rooms.any((r) => r.id == roomId && r.accessCode == accessCode)) {
      throw FirebaseException(plugin: 'firestore', code: 'permission-denied');
    }
    _uid = 'boarder-$roomId';
    _roomId = roomId;
  }

  @override
  Future<void> signOut() async {
    _uid = null;
    _roomId = null;
  }

  @override
  Future<String?> getSession() async => _roomId;

  @override
  Future<bool> isOwnerAccount() async => _uid != null && _uid == owner.id;

  @override
  Future<Owner?> getOwner() async => owner;

  @override
  Stream<Owner?> ownerStream() => _ownerController.stream;

  @override
  Future<void> updateOwner(Owner owner) async {
    this.owner = owner;
    _ownerController.add(owner);
  }

  @override
  Future<List<Room>> getRooms() async => List.of(rooms);

  @override
  Stream<List<Room>> roomsStream() => _roomsController.stream;

  @override
  Future<Map<String, String>> getAccessCodes() async {
    return {for (final room in rooms) room.id: room.accessCode};
  }

  @override
  Stream<Map<String, String>> accessCodesStream() => _codesController.stream;

  // like Firestore after the owner resets this boarder's code:
  // the rooms stream fails with permission-denied
  void revokeSession() {
    _roomsController.addError(
      FirebaseException(plugin: 'firestore', code: 'permission-denied'),
    );
  }

  @override
  Future<void> insertRoom(Room room) async {
    rooms = [...rooms, room];
    _roomsController.add(List.of(rooms));
    _codesController.add(await getAccessCodes());
  }

  // like the real one: never changes the code
  @override
  Future<void> updateRoom(Room room) async {
    rooms = rooms.map((r) {
      if (r.id != room.id) return r;
      return Room(
        id: r.id,
        accessCode: r.accessCode,
        monthlyRent: room.monthlyRent,
        boarderName: room.boarderName,
        contactNumber: room.contactNumber,
        age: room.age,
        emergencyContactName: room.emergencyContactName,
        emergencyContactNumber: room.emergencyContactNumber,
      );
    }).toList();
    _roomsController.add(List.of(rooms));
  }

  @override
  Future<void> resetAccessCode(String roomId, String newCode) async {
    rooms = rooms.map((r) {
      if (r.id != roomId) return r;
      return Room(id: r.id, accessCode: newCode, monthlyRent: r.monthlyRent);
    }).toList();
    _roomsController.add(List.of(rooms));
    _codesController.add(await getAccessCodes());
  }

  // ANNOUNCEMENTS (newest first, like the real query)

  List<Announcement> _sortedAnnouncements() {
    return List.of(announcements)
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
  }

  @override
  Future<List<Announcement>> getAnnouncements() async => _sortedAnnouncements();

  @override
  Stream<List<Announcement>> announcementsStream() =>
      _announcementsController.stream;

  // like a Firestore listener failing for a moment (e.g. no internet)
  void failAnnouncementsStream() {
    _announcementsController.addError(
      FirebaseException(plugin: 'firestore', code: 'unavailable'),
    );
  }

  @override
  Future<String> insertAnnouncement(Announcement announcement) async {
    final id = _newId();
    announcements = [
      ...announcements,
      Announcement(
        id: id,
        title: announcement.title,
        message: announcement.message,
        eventDate: announcement.eventDate,
        createdAt: announcement.createdAt,
      ),
    ];
    _announcementsController.add(_sortedAnnouncements());
    return id;
  }

  @override
  Future<void> updateAnnouncement(Announcement announcement) async {
    announcements = announcements
        .map((a) => a.id == announcement.id ? announcement : a)
        .toList();
    _announcementsController.add(_sortedAnnouncements());
  }

  @override
  Future<void> deleteAnnouncement(String id) async {
    announcements = announcements.where((a) => a.id != id).toList();
    _announcementsController.add(_sortedAnnouncements());
  }
}
