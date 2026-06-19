import 'package:mooze_mobile/features/address_explorer/domain/entities/address_utxo.dart';
import 'package:mooze_mobile/features/address_explorer/domain/enums/address_chain.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

Asset? assetForUtxo(AddressChain chain, String? assetId) {
  if (chain == AddressChain.bitcoin) return Asset.btc;
  if (assetId == null) return null;
  final asset = Asset.fromId(assetId);
  if (asset == Asset.btc) return null;
  return asset;
}

String formatUtxoAmount(AddressChain chain, String? assetId, BigInt value) {
  final asset = assetForUtxo(chain, assetId);
  if (asset != null) return asset.formatBalance(value);
  return '$value · ${shortAssetId(assetId)}';
}

Map<String, List<AddressUtxo>> groupUtxosByAsset(List<AddressUtxo> utxos) {
  final groups = <String, List<AddressUtxo>>{};
  for (final u in utxos) {
    final key =
        u.chain == AddressChain.bitcoin ? btcAssetId : (u.assetId ?? 'unknown');
    groups.putIfAbsent(key, () => []).add(u);
  }
  return groups;
}

List<String> groupedBalances(List<AddressUtxo> utxos) {
  final out = <String>[];
  groupUtxosByAsset(utxos).forEach((_, group) {
    final total = group.fold<BigInt>(BigInt.zero, (s, u) => s + u.value);
    out.add(formatUtxoAmount(group.first.chain, group.first.assetId, total));
  });
  return out;
}

String shortAssetId(String? id) {
  if (id == null || id.isEmpty) return '—';
  if (id.length <= 12) return id;
  return '${id.substring(0, 6)}…${id.substring(id.length - 4)}';
}

String shortOutpoint(String outpoint) {
  if (outpoint.isEmpty) return '—';
  final colon = outpoint.indexOf(':');
  final txid = colon < 0 ? outpoint : outpoint.substring(0, colon);
  if (txid.length <= 16) return outpoint;
  return '${txid.substring(0, 8)}…${txid.substring(txid.length - 4)}';
}
