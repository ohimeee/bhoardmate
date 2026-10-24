import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

import '../models/announcement.dart';
import '../models/concern.dart';
import '../models/owner.dart';
import '../models/payment.dart';
import '../models/room.dart';

// the only class that talks to Firebase, providers call this
class DatabaseService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String? get currentUid => _auth.currentUser?.uid;

  // LOGIN

  Future<void> signInOwner(String email, String password) async {
    await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // anonymous sign-in, then save the session.
  // firestore.rules only accept it if the code matches the room
  Future<void> signInBoarder(String roomId, String accessCode) async {
    final result = await _auth.signInAnonymously();
    try {
      await _db.collection('sessions').doc(result.user!.uid).set({
        'roomId': roomId,
        'accessCode': accessCode,
      });
    } catch (e) {
      // wrong code, remove the anonymous account again
      await result.user!.delete();
      rethrow;
    }
  }

  Future<void> signOut() async {
    await _auth.signOut();
  }

  // room id of the logged in boarder, null if there is no session
  Future<String?> getSession() async {
    final uid = currentUid;
    if (uid == null) return null;
    final doc = await _db.collection('sessions').doc(uid).get();
    if (!doc.exists) return null;
    return doc.data()!['roomId'] as String;
  }

  Future<bool> isOwnerAccount() async {
    final uid = currentUid;
    if (uid == null) return false;
    final doc = await _db.collection('owners').doc(uid).get();
    return doc.exists;
  }

  // OWNER

  Future<Owner?> getOwner() async {
    final snapshot = await _db.collection('owners').limit(1).get();
    if (snapshot.docs.isEmpty) return null;
    final doc = snapshot.docs.first;
    return Owner.fromMap(doc.id, doc.data());
  }

  Stream<Owner?> ownerStream() {
    return _db.collection('owners').limit(1).snapshots().map((snapshot) {
      if (snapshot.docs.isEmpty) return null;
      final doc = snapshot.docs.first;
      return Owner.fromMap(doc.id, doc.data());
    });
  }

  // only name and contact number, the login email stays the same
  Future<void> updateOwner(Owner owner) async {
    await _db.collection('owners').doc(owner.id).update({
      'name': owner.name,
      'contactNumber': owner.contactNumber,
    });
  }

  // ROOMS
  // room info is in rooms/ (boarders can read it for the Members screen),
  // access codes are in roomCodes/ (only the owner can read them)

  Future<Room?> getRoom(String id) async {
    final doc = await _db.collection('rooms').doc(id).get();
    if (!doc.exists) return null;
    return Room.fromMap(doc.id, doc.data()!);
  }

  Future<List<Room>> getRooms() async {
    final snapshot = await _db.collection('rooms').get();
    return snapshot.docs
        .map((doc) => Room.fromMap(doc.id, doc.data()))
        .toList();
  }

  Stream<List<Room>> roomsStream() {
    return _db
        .collection('rooms')
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Room.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  // owner only: room id -> access code
  Future<Map<String, String>> getAccessCodes() async {
    final snapshot = await _db.collection('roomCodes').get();
    final codes = <String, String>{};
    for (final doc in snapshot.docs) {
      codes[doc.id] = doc.data()['accessCode'] as String;
    }
    return codes;
  }

  Future<void> insertRoom(Room room) async {
    final data = room.toMap();
    data.remove('accessCode');
    // batch = both writes happen together or not at all
    final batch = _db.batch();
    batch.set(_db.collection('rooms').doc(room.id), data);
    batch.set(_db.collection('roomCodes').doc(room.id), {
      'accessCode': room.accessCode,
    });
    await batch.commit();
  }

  // never touches the code, use resetAccessCode for that
  Future<void> updateRoom(Room room) async {
    final data = room.toMap();
    data.remove('accessCode');
    await _db.collection('rooms').doc(room.id).update(data);
  }

  // new tenant: new code and the old boarder's info is cleared.
  // the old boarder's session no longer matches, so they are locked out
  Future<void> resetAccessCode(String roomId, String newCode) async {
    final batch = _db.batch();
    batch.set(_db.collection('roomCodes').doc(roomId), {'accessCode': newCode});
    batch.update(_db.collection('rooms').doc(roomId), {
      'boarderName': null,
      'contactNumber': null,
      'age': null,
      'emergencyContactName': null,
      'emergencyContactNumber': null,
    });
    await batch.commit();
  }

  // PAYMENTS
  // boarders must pass their roomId, the rules reject other rooms

  Future<List<Payment>> getPayments({String? roomId}) async {
    Query<Map<String, dynamic>> query = _db.collection('payments');
    if (roomId != null) query = query.where('roomId', isEqualTo: roomId);
    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => Payment.fromMap(doc.id, doc.data()))
        .toList();
  }

  Stream<List<Payment>> paymentsStream({String? roomId}) {
    Query<Map<String, dynamic>> query = _db.collection('payments');
    if (roomId != null) query = query.where('roomId', isEqualTo: roomId);
    return query.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => Payment.fromMap(doc.id, doc.data()))
          .toList(),
    );
  }

  // returns the new document id
  Future<String> insertPayment(Payment payment) async {
    final doc = await _db.collection('payments').add(payment.toMap());
    return doc.id;
  }

  Future<void> updatePayment(Payment payment) async {
    await _db.collection('payments').doc(payment.id).update(payment.toMap());
  }

  Future<void> deletePayment(String id) async {
    await _db.collection('payments').doc(id).delete();
  }

  // ANNOUNCEMENTS (newest first)

  Future<List<Announcement>> getAnnouncements() async {
    final snapshot = await _db
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .get();
    return snapshot.docs
        .map((doc) => Announcement.fromMap(doc.id, doc.data()))
        .toList();
  }

  Stream<List<Announcement>> announcementsStream() {
    return _db
        .collection('announcements')
        .orderBy('createdAt', descending: true)
        .snapshots()
        .map(
          (snapshot) => snapshot.docs
              .map((doc) => Announcement.fromMap(doc.id, doc.data()))
              .toList(),
        );
  }

  Future<String> insertAnnouncement(Announcement announcement) async {
    final doc = await _db.collection('announcements').add(announcement.toMap());
    return doc.id;
  }

  Future<void> updateAnnouncement(Announcement announcement) async {
    await _db
        .collection('announcements')
        .doc(announcement.id)
        .update(announcement.toMap());
  }

  Future<void> deleteAnnouncement(String id) async {
    await _db.collection('announcements').doc(id).delete();
  }

  // CONCERNS
  // boarders must pass their roomId, same as payments

  Future<List<Concern>> getConcerns({String? roomId}) async {
    Query<Map<String, dynamic>> query = _db.collection('concerns');
    if (roomId != null) query = query.where('roomId', isEqualTo: roomId);
    final snapshot = await query.get();
    return snapshot.docs
        .map((doc) => Concern.fromMap(doc.id, doc.data()))
        .toList();
  }

  Stream<List<Concern>> concernsStream({String? roomId}) {
    Query<Map<String, dynamic>> query = _db.collection('concerns');
    if (roomId != null) query = query.where('roomId', isEqualTo: roomId);
    return query.snapshots().map(
      (snapshot) => snapshot.docs
          .map((doc) => Concern.fromMap(doc.id, doc.data()))
          .toList(),
    );
  }

  Future<String> insertConcern(Concern concern) async {
    final doc = await _db.collection('concerns').add(concern.toMap());
    return doc.id;
  }

  Future<void> updateConcern(Concern concern) async {
    await _db.collection('concerns').doc(concern.id).update(concern.toMap());
  }

  Future<void> deleteConcern(String id) async {
    await _db.collection('concerns').doc(id).delete();
  }
}
