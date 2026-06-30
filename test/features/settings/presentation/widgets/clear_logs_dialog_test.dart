import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/features/settings/presentation/widgets/logs/clear_logs_dialog.dart';

void main() {
  void setLargeScreen(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 1920);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  Widget buildApp({
    required void Function(String?) onResult,
    int totalLogs = 42,
    int dbLogs = 100,
  }) {
    return MaterialApp(
      home: Builder(
        builder: (context) => Scaffold(
          body: ElevatedButton(
            onPressed: () async {
              final result = await ClearLogsDialog.show(
                context,
                totalLogs: totalLogs,
                dbLogs: dbLogs,
              );
              onResult(result);
            },
            child: const Text('Open'),
          ),
        ),
      ),
    );
  }

  Future<void> openDialog(WidgetTester tester, {int totalLogs = 42, int dbLogs = 100}) async {
    setLargeScreen(tester);
    await tester.pumpWidget(buildApp(
      onResult: (_) {},
      totalLogs: totalLogs,
      dbLogs: dbLogs,
    ));
    await tester.tap(find.text('Open'));
    await tester.pumpAndSettle();
  }

  group('ClearLogsDialog', () {
    testWidgets('should display title and subtitle', (tester) async {
      await openDialog(tester);

      expect(find.text('Limpar Logs'), findsOneWidget);
      expect(find.text('Escolha o que deseja limpar:'), findsOneWidget);
    });

    testWidgets('should display all clear options', (tester) async {
      await openDialog(tester);

      expect(find.text('Memória'), findsOneWidget);
      expect(find.text('Banco de Dados'), findsOneWidget);
      expect(find.text('Todos'), findsOneWidget);
    });

    testWidgets('should display log counts in descriptions', (tester) async {
      await openDialog(tester);

      expect(
        find.text('Limpar apenas logs em memória (42 logs)'),
        findsOneWidget,
      );
      expect(
        find.text('Limpar apenas logs do banco (100 logs)'),
        findsOneWidget,
      );
    });

    testWidgets('should display cancel button', (tester) async {
      await openDialog(tester);

      expect(find.text('Cancelar'), findsOneWidget);
    });

    testWidgets('should display warning icon', (tester) async {
      await openDialog(tester);

      expect(find.byIcon(Icons.delete_sweep), findsWidgets);
    });

    testWidgets('should display option icons', (tester) async {
      await openDialog(tester);

      expect(find.byIcon(Icons.memory), findsOneWidget);
      expect(find.byIcon(Icons.storage), findsOneWidget);
      expect(find.byIcon(Icons.delete_forever), findsOneWidget);
    });

    testWidgets('should return memory when memory option is tapped',
        (tester) async {
      setLargeScreen(tester);
      String? result;

      await tester.pumpWidget(buildApp(
        onResult: (r) => result = r,
        totalLogs: 10,
        dbLogs: 20,
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Memória'));
      await tester.pumpAndSettle();

      expect(result, 'memory');
    });

    testWidgets('should return database when database option is tapped',
        (tester) async {
      setLargeScreen(tester);
      String? result;

      await tester.pumpWidget(buildApp(
        onResult: (r) => result = r,
        totalLogs: 10,
        dbLogs: 20,
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Banco de Dados'));
      await tester.pumpAndSettle();

      expect(result, 'database');
    });

    testWidgets('should return all when all option is tapped',
        (tester) async {
      setLargeScreen(tester);
      String? result;

      await tester.pumpWidget(buildApp(
        onResult: (r) => result = r,
        totalLogs: 10,
        dbLogs: 20,
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Todos'));
      await tester.pumpAndSettle();

      expect(result, 'all');
    });

    testWidgets('should return null when cancel is tapped', (tester) async {
      setLargeScreen(tester);
      String? result = 'initial';

      await tester.pumpWidget(buildApp(
        onResult: (r) => result = r,
        totalLogs: 10,
        dbLogs: 20,
      ));

      await tester.tap(find.text('Open'));
      await tester.pumpAndSettle();

      await tester.tap(find.text('Cancelar'));
      await tester.pumpAndSettle();

      expect(result, isNull);
    });
  });
}
