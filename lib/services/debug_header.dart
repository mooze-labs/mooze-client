
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
  final DateTime generatedAt;

  String format() {
    final tipLine = bitcoinTip != null && bitcoinTip! > 0
        ? '#$bitcoinTip'
        : 'unavailable';
    final retentionLine =
        logRetentionDays >= 0 ? '$logRetentionDays days' : 'N/A';

    return '''
Mooze App - Debug Info

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
