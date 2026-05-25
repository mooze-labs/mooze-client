
class DebugHeader {
  DebugHeader({
    required this.appVersion,
    required this.buildNumber,
    required this.lwkVersion,
    required this.bdkVersion,
    required this.breezVersion,
    required this.bitcoinTip,
    required this.totalSats,
    required this.totalLogsMemory,
    required this.totalLogsDatabase,
    required this.logRetentionDays,
    this.userId,
    this.walletId,
    DateTime? generatedAt,
  }) : generatedAt = generatedAt ?? DateTime.now();

  final String appVersion;
  final String buildNumber;
  final String lwkVersion;
  final String bdkVersion;
  final String breezVersion;
  final int? bitcoinTip;
  final int totalSats;
  final int totalLogsMemory;
  final int totalLogsDatabase;
  final int logRetentionDays;

  /// Backend-issued user id (from `UserService.getUser()`). Nullable
  /// because the call is async + auth-gated; if the export is built
  /// while the user-info call is in flight or has failed, we still
  /// want the rest of the header to render.
  final String? userId;

  /// Locally-generated per-wallet id (from `WalletIdService`). Always
  /// available once the wallet has booted; included alongside
  /// [userId] because support tickets often need both to correlate
  /// device-side state with backend records.
  final String? walletId;
  final DateTime generatedAt;

  String format() {
    final tipLine = bitcoinTip != null && bitcoinTip! > 0
        ? '#$bitcoinTip'
        : 'unavailable';
    final retentionLine =
        logRetentionDays >= 0 ? '$logRetentionDays days' : 'N/A';
    final userIdLine = userId ?? 'unavailable';
    final walletIdLine = walletId ?? 'unavailable';

    return '''
Mooze App - Debug Info

User ID: $userIdLine
Wallet ID: $walletIdLine
App Version: $appVersion
Build Number: $buildNumber
LWK: $lwkVersion
BDK: $bdkVersion
Breez SDK: $breezVersion
Bitcoin tip: $tipLine
Total Sats (sum across chains): $totalSats
Total Logs (Memory): $totalLogsMemory
Total Logs (Database): $totalLogsDatabase
Log Retention: $retentionLine
Generated: ${generatedAt.toIso8601String()}
''';
  }
}
