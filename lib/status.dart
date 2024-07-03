import 'package:cloud_firestore/cloud_firestore.dart';


class Status {
  final String id;
  final String message;
  final bool isActive;
  final String name;
  final DateTime timestamp;



  Status({required this.id, required this.name, required this.message, required this.isActive, required this.timestamp});

  factory Status.fromMap(Map<String, dynamic> data, String id) {
    return Status(
      id: id,
      message: data['message'] ?? '',
      isActive: data['isActive'] ?? false,
      name: data["name"] ?? '',
      timestamp: (data['timestamp'] as Timestamp).toDate(),      
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'isActive': isActive,
      'name': name,
      'timestamp' : timestamp
    };
  }
}