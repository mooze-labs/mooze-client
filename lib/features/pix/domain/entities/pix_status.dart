class PixStatusUpdate {
  final String id;
  final String status;
  final String? message;

  PixStatusUpdate({required this.id, required this.status, this.message});

  factory PixStatusUpdate.fromJson(Map<String, dynamic> json) {
    return PixStatusUpdate(
      id: json['id'] as String,
      status: json['status'] as String,
      message: json['message'] as String?,
    );
  }
}
