import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:mooze_mobile/features/pix/send_pix/presentation/widgets/clipboard_pix_key_suggestion.dart';
import 'package:mooze_mobile/infra/core/core_sync_helpers.dart';

import '../../../shared/fake_core_sync_helpers.dart';

class _MockHelpers extends Mock implements CoreSyncHelpers {}

void main() {
  final helpers = _MockHelpers();
  useCoreSyncHelpers(helpers);
  tearDown(() => reset(helpers));

  test('PixKeyDetector returns the core decision', () {
    when(() => helpers.pixLooksLikeKey('someone@example.com')).thenReturn(true);
    when(() => helpers.pixLooksLikeKey('hello world')).thenReturn(false);

    expect(PixKeyDetector.looksLikePixKey('someone@example.com'), isTrue);
    expect(PixKeyDetector.looksLikePixKey('hello world'), isFalse);
    verify(() => helpers.pixLooksLikeKey(any())).called(2);
  });
}
