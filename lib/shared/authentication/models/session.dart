import 'dart:convert';

import 'package:fpdart/fpdart.dart';

class Session {
  final String jwt;
  final String refreshToken;

  Session({required this.jwt, required this.refreshToken});

  factory Session.fromJson(Map<String, dynamic> json) {
    final data = json['data'] ?? json;
    return Session(jwt: data['jwt'], refreshToken: data['refresh_token']);
  }

  Either<String, bool> isExpired() {
    try {
      final payload = _parseJwt(jwt);
      if (payload['exp'] == null) {
        return left('Token does not contain expiry date');
      }

      // Check if exp is a valid number
      final exp = payload['exp'];
      if (exp is! num) {
        return left('Token expiry date is not a valid number');
      }

      final expiresAt = DateTime.fromMillisecondsSinceEpoch(
        (exp * 1000).round(),
      );
      return right(expiresAt.isBefore(DateTime.now()));
    } catch (e) {
      return left('Failed to parse token: ${e.toString()}');
    }
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
