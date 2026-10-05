import '../entities/chain.dart';

/// What the boot orchestrator passes to chain services on connect.
/// The mnemonic is in-memory only — never logged, never persisted in plaintext.
class WalletCredentials {
  const WalletCredentials({required this.mnemonic, required this.network});
  final String mnemonic;
  final AppNetwork network;

  /// Convenience helper: when no mnemonic exists yet, returns a sentinel
  /// instead of throwing. Use [isAbsent] to check first.
  factory WalletCredentials.absent(AppNetwork network) =>
      WalletCredentials(mnemonic: '', network: network);

  bool get isAbsent => mnemonic.isEmpty;

  @override
  String toString() =>
      'WalletCredentials(network: ${network.name}, mnemonic: <redacted>)';
}
