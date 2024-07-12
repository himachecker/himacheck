// status.dart

import 'package:cloud_firestore/cloud_firestore.dart';

class Status {
  final String id;
  final String message;
  final bool isActive;
  final String name;
  final DateTime timestamp;

  Status({
    required this.id,
    required this.message,
    required this.isActive,
    required this.name,
    required this.timestamp,
  });

  factory Status.fromFirestore(DocumentSnapshot doc) {
    Map<String, dynamic> data = doc.data() as Map<String, dynamic>;
    return Status(
      id: doc.id,
      message: data['message'] ?? '',
      isActive: data['isActive'] ?? false,
      name: data['name'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  factory Status.fromMap(Map<String, dynamic> data, String documentId) {
    return Status(
      id: documentId,
      message: data['message'] ?? '',
      isActive: data['isActive'] ?? false,
      name: data['name'] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'isActive': isActive,
      'name': name,
      'timestamp': Timestamp.fromDate(timestamp),
    };
  }
}
