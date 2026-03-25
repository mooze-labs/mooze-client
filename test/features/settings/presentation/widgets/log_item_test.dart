import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/logs/log_item.dart';
import 'package:mooze_mobile/services/app_logger_service.dart';

void main() {
  LogEntry createLogEntry({
    LogLevel level = LogLevel.info,
    String tag = 'TestTag',
    String message = 'Test message',
    DateTime? timestamp,
  }) {
    return LogEntry(
      timestamp: timestamp ?? DateTime(2024, 1, 15, 14, 30, 45),
      level: level,
      tag: tag,
      message: message,
    );
  }

  Widget buildWidget(LogEntry log, {VoidCallback? onTap}) {
    return MaterialApp(
      home: Scaffold(
        body: LogItem(
          log: log,
          onTap: onTap ?? () {},
        ),
      ),
    );
  }

  group('LogItem', () {
    testWidgets('should display formatted timestamp', (tester) async {
      final log = createLogEntry();
      await tester.pumpWidget(buildWidget(log));

      expect(find.text('14:30:45'), findsOneWidget);
    });

    testWidgets('should display log level name', (tester) async {
      final log = createLogEntry(level: LogLevel.warning);
      await tester.pumpWidget(buildWidget(log));

      expect(find.text('WARNING'), findsOneWidget);
    });

    testWidgets('should display tag', (tester) async {
      final log = createLogEntry(tag: 'MyService');
      await tester.pumpWidget(buildWidget(log));

      expect(find.text('MyService'), findsOneWidget);
    });

    testWidgets('should display message', (tester) async {
      final log = createLogEntry(message: 'Something happened');
      await tester.pumpWidget(buildWidget(log));

      expect(find.text('Something happened'), findsOneWidget);
    });

    testWidgets('should invoke onTap callback when tapped', (tester) async {
      bool tapped = false;
      final log = createLogEntry();

      await tester.pumpWidget(buildWidget(log, onTap: () => tapped = true));
      await tester.tap(find.byType(LogItem));

      expect(tapped, isTrue);
    });

    testWidgets('should render all log levels without errors', (tester) async {
      for (final level in LogLevel.values) {
        final log = createLogEntry(level: level);
        await tester.pumpWidget(buildWidget(log));

        expect(find.text(level.displayName), findsOneWidget);
      }
    });
  });
}
