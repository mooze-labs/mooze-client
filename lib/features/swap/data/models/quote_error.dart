/// Error result for a quote attempt
class QuoteError {
  final String errorMessage;

  QuoteError({required this.errorMessage});

  factory QuoteError.fromJson(Map<String, dynamic> json) {
    return QuoteError(errorMessage: json['status']['Error']['error_msg']);
  }
}
