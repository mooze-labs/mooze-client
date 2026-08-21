class LiquidFeeRate {
  const LiquidFeeRate._();

  static const double minSatPerKvb = 100.0;

  static const double defaultSatPerKvb = minSatPerKvb;

  static double fromSatPerVb(double? satPerVb) {
    if (satPerVb == null || !satPerVb.isFinite || satPerVb <= 0) {
      return defaultSatPerKvb;
    }
    final satPerKvb = satPerVb * 1000.0;
    return satPerKvb < minSatPerKvb ? minSatPerKvb : satPerKvb;
  }

  static double toSatPerVb(double satPerKvb) => satPerKvb / 1000.0;
}
