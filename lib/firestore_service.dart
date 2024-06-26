import 'package:cloud_firestore/cloud_firestore.dart';
import 'status.dart';

class FirestoreService {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  Stream<List<Status>> getStatuses() {
    return _db.collection('statuses').snapshots().map((snapshot) => snapshot.docs
        .map((doc) => Status.fromMap(doc.data(), doc.id))
        .toList());
  }

  Future<void> updateStatus(String id, bool isActive, String message) async {
    try {
      await _db.collection('statuses').doc(id).update({
        'isActive': isActive,
        'message': message,
      });
    } catch (e) {
      throw Exception('Error updating status: $e');
    }
  }

  Future<void> addStatus(String message, bool isActive) async {
    try {
      await _db.collection('statuses').add({
        'isActive': isActive,
        'message': message,
      });
    } catch (e) {
      throw Exception('Error adding status: $e');
    }
  }
}
