class VerificationStatus {
  final String status;
  final String? message;

  const VerificationStatus({required this.status, this.message});

  factory VerificationStatus.fromJson(Map<String, dynamic> json) {
    return VerificationStatus(
      status: json['status'] as String,
      message: json['message'] as String?,
    );
  }
}
