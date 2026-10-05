import 'dart:async';
import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/widgets.dart';
import 'package:mooze_mobile/domain/failures/failure.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/exceptions/user_friendly_exception.dart';

/// Converts any thrown object into copy that is safe to show to a user.
///
/// Raw `toString()` output leaks class names, stack fragments and server
/// payloads. This keeps the technical text for the logs and picks a
/// localized message by error family instead. Unknown errors fall back to a
/// generic "something went wrong" line.
String humanizeError(BuildContext context, Object? error) {
  final t = AppLocalizations.of(context);

  if (error == null) return t.error_something_went_wrong;

  if (error is UserFriendlyException) return error.userMessage;

  if (error is Failure) {
    return switch (error) {
      SyncFailure() || ServiceFailure() => t.error_server_communication,
      CredentialFailure() || SessionFailure() => t.error_authentication_failed,
      StorageFailure() => t.error_load_data,
      BootFailure() ||
      PlatformFailure() ||
      UnexpectedFailure() => t.error_something_went_wrong,
    };
  }

  if (error is DioException) {
    switch (error.type) {
      case DioExceptionType.connectionError:
      case DioExceptionType.connectionTimeout:
      case DioExceptionType.sendTimeout:
      case DioExceptionType.receiveTimeout:
        return t.error_no_internet;
      case DioExceptionType.badResponse:
        final status = error.response?.statusCode ?? 0;
        if (status == 401) return t.error_authentication_failed;
        if (status == 403) return t.error_access_denied;
        if (status == 404) return t.error_service_not_found;
        if (status >= 500) return t.error_server_unavailable;
        return t.error_server_communication;
      case DioExceptionType.cancel:
      case DioExceptionType.badCertificate:
      case DioExceptionType.unknown:
        return t.error_server_communication;
    }
  }

  if (error is SocketException || error is TimeoutException) {
    return t.error_no_internet;
  }

  if (error is String) {
    // Strings coming out of `Either.left` are sometimes already user copy
    // and sometimes a stringified exception. Keep the former only.
    final looksTechnical =
        error.contains('Exception') ||
        error.contains('Error:') ||
        error.contains('Failed host lookup') ||
        error.contains('#0 ') ||
        error.length > 160;
    return looksTechnical ? t.error_something_went_wrong : error;
  }

  final text = error.toString();
  if (text.contains('SocketException') || text.contains('Failed host lookup')) {
    return t.error_no_internet;
  }
  if (text.contains('TimeoutException')) return t.error_no_internet;

  return t.error_something_went_wrong;
}
