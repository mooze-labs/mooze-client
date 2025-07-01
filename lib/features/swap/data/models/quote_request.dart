import 'swap_direction.dart';
import 'swap_utxo.dart';

class QuoteRequest {
  String baseAsset;
  String quoteAsset;
  String assetType;
  int amount;
  SwapDirection direction;
  List<SwapUtxo> utxos;
  String receiveAddress;
  String changeAddress;

  QuoteRequest({
    required this.baseAsset,
    required this.quoteAsset,
    required this.assetType,
    required this.amount,
    required this.direction,
    required this.utxos,
    required this.receiveAddress,
    required this.changeAddress,
  });
}
