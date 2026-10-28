/// Log keys and masking for the Pix backend calls.
///
/// Every log line of a call starts with its key, so a search for the key in
/// the debug console or in the exported log finds the whole story of a
/// request. The screens show a translated text only.
library;

/// Key of the payment-link calls (`POST /payment-links`).
const String paymentLinkLogKey = 'MOOZE_PAYMENT_LINK';

/// Key of the Pix withdrawal calls (`/withdraw`).
const String withdrawalLogKey = 'MOOZE_PIX_WITHDRAWAL';

/// Hides emails and runs of 4 or more digits, so a server text that echoes a
/// Pix key or a tax ID does not reach the logs.
String redactForLog(String text) => text
    .replaceAll(RegExp(r'\S+@\S+'), '***@***')
    .replaceAll(RegExp(r'\d{4,}'), '****');

/// The first [max] characters of [text] on one line, masked by
/// [redactForLog].
String logSnippet(String? text, {int max = 120}) {
  final line = (text ?? '').replaceAll(RegExp(r'\s+'), ' ').trim();
  final cut = line.length <= max ? line : '${line.substring(0, max)}…';
  return redactForLog(cut);
}

/// A Liquid address shortened to its start and end, enough to compare two
/// lines without printing the whole address.
String shortAddress(String address) => address.length <= 16
    ? address
    : '${address.substring(0, 8)}…${address.substring(address.length - 6)}';
