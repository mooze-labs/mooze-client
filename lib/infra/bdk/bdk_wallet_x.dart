import 'package:bdk_dart/bdk_dart.dart' as bdk;

/// Flat, FFI-free view of one wallet transaction. Replaces
/// `bdk_flutter`'s `TransactionDetails` for the app's mapping code.
class BdkTxView {
  const BdkTxView({
    required this.txid,
    required this.sentSat,
    required this.receivedSat,
    required this.feeSat,
    required this.confirmationTime,
    required this.confirmationHeight,
    required this.outputScriptHexes,
  });

  final String txid;
  final int sentSat;
  final int receivedSat;

  /// `null` when BDK cannot compute the fee (a previous output is missing).
  final int? feeSat;

  /// Block time of the confirming block; `null` while unconfirmed.
  final DateTime? confirmationTime;
  final int? confirmationHeight;

  /// Hex of every output script. Used to detect addresses that received
  /// funds.
  final List<String> outputScriptHexes;

  bool get isConfirmed => confirmationTime != null;
}

/// Hex encoding of a script, the key the app uses to compare scripts.
String bdkScriptHex(bdk.Script script) {
  final buf = StringBuffer();
  for (final b in script.toBytes()) {
    buf.write(b.toRadixString(16).padLeft(2, '0'));
  }
  return buf.toString();
}

extension BdkWalletX on bdk.Wallet {
  /// Every canonical wallet transaction, as [BdkTxView]s.
  List<BdkTxView> txViews() {
    final views = <BdkTxView>[];
    for (final canonical in transactions()) {
      final tx = canonical.transaction;
      final txid = tx.computeTxid();
      final details = txDetails(txid: txid);
      final values = details == null ? sentAndReceived(tx: tx) : null;

      DateTime? confirmedAt;
      int? height;
      final position = canonical.chainPosition;
      if (position is bdk.ConfirmedChainPosition) {
        final block = position.confirmationBlockTime;
        confirmedAt = DateTime.fromMillisecondsSinceEpoch(
          block.confirmationTime * 1000,
        );
        height = block.blockId.height;
      }

      views.add(
        BdkTxView(
          txid: txid.toString(),
          sentSat: (details?.sent ?? values!.sent).toSat(),
          receivedSat: (details?.received ?? values!.received).toSat(),
          feeSat: details?.fee?.toSat(),
          confirmationTime: confirmedAt,
          confirmationHeight: height,
          outputScriptHexes: [
            for (final out in tx.output()) bdkScriptHex(out.scriptPubkey),
          ],
        ),
      );
    }
    return views;
  }

  /// Scripts that ever received funds: current UTXOs plus every output of
  /// every wallet transaction.
  Set<String> usedScriptHexes() {
    final used = <String>{};
    for (final u in listUnspent()) {
      used.add(bdkScriptHex(u.txout.scriptPubkey));
    }
    for (final canonical in transactions()) {
      for (final out in canonical.transaction.output()) {
        used.add(bdkScriptHex(out.scriptPubkey));
      }
    }
    return used;
  }

  /// Receive address at [index], without revealing it.
  bdk.AddressInfo peekReceive(int index) =>
      peekAddress(keychain: bdk.KeychainKind.external_, index: index);

  /// Next receive address with no on-chain history.
  ///
  /// Starts from BDK's first unused revealed address and walks forward past
  /// any address whose script already appears in the wallet's history. This
  /// guards against handing out an address that a restored or externally
  /// used seed already funded. Reveals up to the chosen index so later calls
  /// never go backwards; the caller must persist the wallet afterwards.
  ///
  /// Throws [StateError] if no unused address exists within [cap] indexes.
  bdk.AddressInfo nextFreshReceiveAddress({int cap = 100}) {
    final used = usedScriptHexes();
    var info = nextUnusedAddress(keychain: bdk.KeychainKind.external_);
    var walked = 0;
    while (used.contains(bdkScriptHex(info.address.scriptPubkey())) &&
        walked < cap) {
      walked++;
      info = peekReceive(info.index + 1);
    }
    if (used.contains(bdkScriptHex(info.address.scriptPubkey()))) {
      throw StateError(
        'no unused receive address found within $cap-index window',
      );
    }
    revealAddressesTo(keychain: bdk.KeychainKind.external_, index: info.index);
    return info;
  }
}
