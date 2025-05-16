import 'package:mooze_mobile/models/assets.dart';

class PixInputModel {
  final int amountInCents;
  final Asset asset;
  final String address;

  PixInputModel({
    required this.amountInCents,
    required this.asset,
    required this.address,
  });

  PixInputModel copyWith({int? amountInCents, Asset? asset, String? address}) {
    return PixInputModel(
      amountInCents: amountInCents ?? this.amountInCents,
      asset: asset ?? this.asset,
      address: address ?? this.address,
    );
  }
}
