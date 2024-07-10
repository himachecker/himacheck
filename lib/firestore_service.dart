// firestore_service.dart

import 'package:cloud_firestore/cloud_firestore.dart';
import 'status.dart';

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
}
