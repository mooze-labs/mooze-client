import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/settings/presentation/screens/developer_screen.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/export_logs_dialog.dart';

void main() {
  Future<void> openDialog(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        home: Builder(
          builder: (context) => Scaffold(
            body: ElevatedButton(
              onPressed: () {
                ExportLogsDialog.show(context);
              },
              child: const Text('Open'),
            ),
          ),
        ),
      ),
    );

    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  group('ExportLogsDialog', () {
    testWidgets('should display title', (tester) async {
      await openDialog(tester);

      expect(find.text('Exportar Logs'), findsOneWidget);
    });

    testWidgets('should display description text', (tester) async {
      await openDialog(tester);

      expect(
        find.text(
          'Os logs do aplicativo ajudam nossa equipe a resolver problemas. Como você gostaria de compartilhar?',
        ),
        findsOneWidget,
      );
    });

    testWidgets('should display email button', (tester) async {
      await openDialog(tester);

      expect(find.text('Enviar por E-mail'), findsOneWidget);
    });

    testWidgets('should display share button', (tester) async {
      await openDialog(tester);

      expect(find.text('Salvar/Compartilhar'), findsOneWidget);
    });

    testWidgets('should display download icon', (tester) async {
      await openDialog(tester);

      expect(find.byIcon(Icons.file_download), findsOneWidget);
    });

    testWidgets('should return email when email button is tapped',
        (tester) async {
      ExportMethod? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  result = await ExportLogsDialog.show(context);
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Enviar por E-mail'));
      await tester.pumpAndSettle();

      expect(result, ExportMethod.email);
    });

    testWidgets('should return share when share button is tapped',
        (tester) async {
      ExportMethod? result;

      await tester.pumpWidget(
        MaterialApp(
          home: Builder(
            builder: (context) => Scaffold(
              body: ElevatedButton(
                onPressed: () async {
                  result = await ExportLogsDialog.show(context);
                },
                child: const Text('Open'),
              ),
            ),
          ),
        ),
      );

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Salvar/Compartilhar'));
      await tester.pumpAndSettle();

      expect(result, ExportMethod.share);
    });
  });
}
