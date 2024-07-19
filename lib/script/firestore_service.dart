// firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/status.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<Status?> getUserStatus(String uid) {
    return _db.collection('statuses').doc(uid).snapshots().map((snapshot) {
      if (snapshot.exists) {
        return Status.fromFirestore(snapshot);
      } else {
        return null;
      }
    });
  }

  Future<void> updateStatus(String uid, bool isActive, String message, String name, DateTime timestamp) async {
    await _db.collection('statuses').doc(uid).update({
      'isActive': isActive,
      'message': message,
      'name': name,
      'timestamp': DateTime.now(), // タイムスタンプを現在の日時で更新
    });
  }

  Future<void> addStatus(String message, bool isActive, String name, DateTime timestamp, String uid) async {
    await _db.collection('statuses').doc(uid).set({
      'isActive': isActive,
      'message': message,
      'name': name,
      'timestamp': timestamp,
    });
  }
  
  Future<void> addFriend(String userId, String friendId) async {
    await _db.collection('users').doc(userId).collection('friends').doc(friendId).set({});
  }

  Stream<List<String>> getFriendIds(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('friends')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) => doc.id).toList());
  }
 
  Stream<List<Status>> getFriendsStatuses(String userId) {
    return _db
        .collection('users')
        .doc(userId)
        .collection('friends')
        .snapshots()
        .asyncMap((snapshot) async {
          if (snapshot.docs.isNotEmpty) {
            List<String> friendIds = snapshot.docs.map((doc) => doc.id).toList();
            QuerySnapshot statusSnapshot = await _db
                .collection('statuses')
                .where(FieldPath.documentId, whereIn: friendIds)
                .get();
            return statusSnapshot.docs
                .map((doc) => Status.fromFirestore(doc))
                .toList();
          } else {
            return [];
          }
        });
  }
    Stream<List<Team>> getUserTeams(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('teams')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Team.fromFirestore(doc.data() as Map<String, dynamic>))
            .toList());
  }


  Stream<List<Friend>> getTeamMembers(String uid, String teamId) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('teams')
        .doc(teamId)
        .collection('members')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Friend.fromFirestore(doc.data() as Map<String, dynamic>))
            .toList());
  }

  Stream<List<Friend>> getUserFriends(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('friends')
        .snapshots()
        .map((snapshot) => snapshot.docs
            .map((doc) => Friend.fromFirestore(doc.data() as Map<String, dynamic>))
            .toList());
  }

  Future<void> createTeam(String uid, String teamName) async {
    await _db.collection('users').doc(uid).collection('teams').doc().set({
        'name': teamName,
        'id': uid});
  }


  Future<void> updateTeam(String uid, String teamId, String teamName) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('teams')
        .doc(teamId)
        .update({'name': teamName});
  }

  Future<void> deleteTeam(String uid, String teamId) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('teams')
        .doc(teamId)
        .delete();
  }

  Future<void> addFriendToTeam(String uid, String teamId, String friendId) async {
    if (uid.isEmpty || teamId.isEmpty || friendId.isEmpty) {
      throw ArgumentError('User ID, Team ID, and Friend ID must not be empty');
    }

    final friendDoc = _db
        .collection('users')
        .doc(uid)
        .collection('teams')
        .doc(teamId)
        .collection('members')
        .doc(friendId);
    await friendDoc.set({'id': friendId});
  }

  Future<void> removeFriendFromTeam(String uid, String teamId, String friendId) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('teams')
        .doc(teamId)
        .collection('members')
        .doc(friendId)
        .delete();
  }
}


