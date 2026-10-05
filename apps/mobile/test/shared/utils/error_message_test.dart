import 'dart:io';

import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/domain/failures/failure.dart';
import 'package:mooze_mobile/l10n/generated/app_localizations.dart';
import 'package:mooze_mobile/shared/exceptions/user_friendly_exception.dart';
import 'package:mooze_mobile/shared/utils/error_message.dart';

void main() {
  late BuildContext ctx;
  late AppLocalizations t;

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        locale: const Locale('en'),
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        home: Builder(
          builder: (c) {
            ctx = c;
            t = AppLocalizations.of(c);
            return const SizedBox();
          },
        ),
      ),
    );
  }

  testWidgets('never leaks raw exception text', (tester) async {
    await pump(tester);
    final msg = humanizeError(ctx, Exception('SQLITE_CONSTRAINT at row 3'));
    expect(msg, t.error_something_went_wrong);
    expect(msg.contains('SQLITE'), isFalse);
  });

  testWidgets('maps families to the existing copy', (tester) async {
    await pump(tester);
    expect(humanizeError(ctx, const SocketException('x')), t.error_no_internet);
    expect(
      humanizeError(
        ctx,
        DioException(
          requestOptions: RequestOptions(path: '/'),
          type: DioExceptionType.connectionTimeout,
        ),
      ),
      t.error_no_internet,
    );
    expect(
      humanizeError(
        ctx,
        DioException(
          requestOptions: RequestOptions(path: '/'),
          type: DioExceptionType.badResponse,
          response: Response(requestOptions: RequestOptions(path: '/'), statusCode: 503),
        ),
      ),
      t.error_server_unavailable,
    );
    expect(
      humanizeError(ctx, const CredentialFailure('bad token')),
      t.error_authentication_failed,
    );
    expect(
      humanizeError(ctx, UserFriendlyException(userMessage: 'Saldo insuficiente')),
      'Saldo insuficiente',
    );
  });

  testWidgets('keeps short human strings, drops technical ones', (tester) async {
    await pump(tester);
    expect(humanizeError(ctx, 'Limite diário atingido'), 'Limite diário atingido');
    expect(
      humanizeError(ctx, 'FormatException: Unexpected character'),
      t.error_something_went_wrong,
    );
  });
}
