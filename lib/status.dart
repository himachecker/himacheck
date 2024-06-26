class Status {
  final String id;
  final String message;
  final bool isActive;

  Status({required this.id, required this.message, required this.isActive});

  factory Status.fromMap(Map<String, dynamic> data, String id) {
    return Status(
      id: id,
      message: data['message'] ?? '',
      isActive: data['isActive'] ?? false,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'message': message,
      'isActive': isActive,
    };
  }
}