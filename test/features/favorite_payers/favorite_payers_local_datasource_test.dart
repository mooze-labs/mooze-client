import 'package:flutter_test/flutter_test.dart';
import 'package:mooze_mobile/database/database.dart';
import 'package:mooze_mobile/features/favorite_payers/data/datasources/favorite_payers_local_datasource.dart';

import '../../shared/database_test_helpers.dart';

void main() {
  late AppDatabase db;
  late FavoritePayersLocalDataSource ds;

  setUp(() {
    db = buildInMemoryDatabase();
    ds = FavoritePayersLocalDataSource(db);
  });
  tearDown(() async => db.close());

  test('insert + getAll returns saved payers with ids', () async {
    await ds.insert('João', '52998224725');
    await ds.insert('Maria', '11144477735');

    final all = await ds.getAll();
    expect(all.map((p) => p.cpf).toSet(), {'52998224725', '11144477735'});
    expect(all.every((p) => p.id != null), isTrue);
  });

  test('update changes label and cpf', () async {
    await ds.insert('João', '52998224725');
    final id = (await ds.getAll()).single.id!;

    await ds.update(id, 'João S.', '11144477735');

    final updated = (await ds.getAll()).single;
    expect(updated.label, 'João S.');
    expect(updated.cpf, '11144477735');
  });

  test('delete removes a payer', () async {
    await ds.insert('João', '52998224725');
    final id = (await ds.getAll()).single.id!;

    await ds.delete(id);

    expect(await ds.getAll(), isEmpty);
  });

  test('clearAll wipes every payer', () async {
    await ds.insert('João', '52998224725');
    await ds.insert('Maria', '11144477735');

    await ds.clearAll();

    expect(await ds.getAll(), isEmpty);
  });

  group('cpfExists', () {
    test('true when present, false otherwise', () async {
      await ds.insert('João', '52998224725');
      expect(await ds.cpfExists('52998224725'), isTrue);
      expect(await ds.cpfExists('11144477735'), isFalse);
    });

    test('excludingId ignores the given row (edit case)', () async {
      await ds.insert('João', '52998224725');
      final id = (await ds.getAll()).single.id!;
      expect(await ds.cpfExists('52998224725', excludingId: id), isFalse);
    });
  });
}
