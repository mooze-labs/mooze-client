import 'dart:convert';

import 'package:fpdart/fpdart.dart';

class Session {
  final String jwt;
  final String refreshToken;

  Session({required this.jwt, required this.refreshToken});

  factory Session.fromJson(Map<String, dynamic> json) {
    return Session(jwt: json['jwt'], refreshToken: json['refresh_token']);
  }

  Either<String, bool> isExpired() {
    final payload = _parseJwt(jwt);
    if (payload['exp'] == null) {
      return left('Token does not contain expiry date');
    }

    final expiresAt = DateTime.fromMillisecondsSinceEpoch(
      payload['exp'] * 1000,
    );
    return right(expiresAt.isBefore(DateTime.now()));
  }

  Map<String, dynamic> _parseJwt(String jwt) {
    final parts = jwt.split('.');
    if (parts.length != 3) {
      throw Exception('invalid token');
    }

    final payload = _decodeJwt(parts[1]);
    final payloadMap = json.decode(payload);
    if (payloadMap is! Map<String, dynamic>) {
      throw Exception('invalid payload');
    }

    return payloadMap;
  }

  String _decodeJwt(String jwt) {
    String output = jwt.replaceAll('-', '+').replaceAll('_', '/');

    switch (output.length % 4) {
      case 0:
        break;
      case 2:
        output += '==';
        break;
      case 3:
        output += '=';
        break;
      default:
        throw Exception('Illegal base64url string!');
    }

    return utf8.decode(base64Url.decode(output));
  }

  /// Create a new Session with updated JWT but same refresh token
  Session copyWithNewJwt(String newJwt) {
    return Session(jwt: newJwt, refreshToken: refreshToken);
  }
}
