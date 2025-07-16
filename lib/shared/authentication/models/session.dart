import 'dart:convert';

class Session {
  final String jwt;
  final String refreshToken;
  final DateTime? expiresAt;

  Session({required this.jwt, required this.refreshToken, this.expiresAt});

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(jwt: json['jwt'], refreshToken: json['refresh_token']);
  }

  /// Creates a Session with expiry information extracted from JWT
  factory Session.withExpiry({
    required String jwt,
    required String refreshToken,
  }) {
    final expiresAt = _extractExpiryFromJwt(jwt);
    return Session(jwt: jwt, refreshToken: refreshToken, expiresAt: expiresAt);
  }

  /// Check if the JWT token is expired or will expire within the buffer time
  bool isExpiredOrNearExpiry({Duration buffer = const Duration(minutes: 5)}) {
    if (expiresAt == null) return false;
    return DateTime.now().add(buffer).isAfter(expiresAt!);
  }

  /// Check if the JWT token is definitely expired
  bool isExpired() {
    if (expiresAt == null) return false;
    return DateTime.now().isAfter(expiresAt!);
  }

  /// Extract expiry date from JWT token
  static DateTime? _extractExpiryFromJwt(String jwt) {
    try {
      final parts = jwt.split('.');
      if (parts.length != 3) return null;

      // Decode the payload (second part)
      final payload = parts[1];

      // Add padding if necessary
      final normalizedPayload = _addPaddingIfNeeded(payload);

      final decodedBytes = base64Url.decode(normalizedPayload);
      final payloadMap = json.decode(utf8.decode(decodedBytes));

      final exp = payloadMap['exp'];
      if (exp == null) return null;

      // Convert from Unix timestamp to DateTime
      return DateTime.fromMillisecondsSinceEpoch(exp * 1000);
    } catch (e) {
      // If we can't decode the JWT, return null
      return null;
    }
  }

  /// Add padding to base64 string if needed
  static String _addPaddingIfNeeded(String base64String) {
    final int remainder = base64String.length % 4;
    if (remainder != 0) {
      return base64String + '=' * (4 - remainder);
    }
    return base64String;
  }

  /// Create a new Session with updated JWT but same refresh token
  Session copyWithNewJwt(String newJwt) {
    return Session.withExpiry(jwt: newJwt, refreshToken: refreshToken);
  }
}
