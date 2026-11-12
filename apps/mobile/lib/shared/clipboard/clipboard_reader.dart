import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

/// Reads the text of the clipboard. Every read of the app goes through it.
///
/// On iOS 16 and later, a read of text that another app copied shows the
/// system "Allow Paste" alert. The alert takes the app out of the active
/// state, so Flutter reports `inactive`, the same event as the app switcher,
/// and the privacy shield would rise over the screen. That `inactive` may
/// arrive while the read waits, or right after its answer, when the alert
/// closes. [mayShowPasteAlert] covers both, so the shield ignores it.
abstract final class ClipboardReader {
  /// How long after an answer the `inactive` of its alert may still arrive.
  /// Short, so an app switch right after it is covered as always.
  static const Duration alertSettle = Duration(seconds: 1);

  /// The clock of [mayShowPasteAlert].
  @visibleForTesting
  static DateTime Function() now = DateTime.now;

  static int _reads = 0;
  static DateTime? _lastAnswer;

  /// True while a read waits, and for [alertSettle] after its answer.
  static bool get mayShowPasteAlert {
    if (_reads > 0) return true;
    final lastAnswer = _lastAnswer;
    return lastAnswer != null && now().difference(lastAnswer) < alertSettle;
  }

  /// The text of the clipboard, or null when it has none.
  static Future<String?> readText() async {
    _reads++;
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      return data?.text;
    } finally {
      _reads--;
      _lastAnswer = now();
    }
  }

  /// Forgets the past reads, between tests.
  @visibleForTesting
  static void debugReset() {
    _reads = 0;
    _lastAnswer = null;
  }
}
