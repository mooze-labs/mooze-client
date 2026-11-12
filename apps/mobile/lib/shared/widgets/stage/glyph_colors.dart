import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:mooze_mobile/shared/entities/asset.dart';

/// Draws the symbol of an asset icon in one [tint], for the face of a coin.
///
/// The icons in `assets/icons/asset` draw the symbol over a colored disc.
/// The coin is the disc here, so the disc of the icon turns clear and the
/// symbol takes [tint]. The drop around the L-BTC ₿ and the dark bar of
/// the DePix symbol take a dimmed [tint], so these symbols keep their two
/// tones.
@immutable
class CoinGlyphColors extends ColorMapper {
  const CoinGlyphColors._(this.tint, this._clear, this._dimmed);

  factory CoinGlyphColors.of(Asset asset, Color tint) => switch (asset) {
    // The orange disc behind the ₿.
    Asset.btc => CoinGlyphColors._(tint, _btcDisc, null),
    // The drop, dimmed, so the ₿ inside it stands out.
    Asset.lbtc => CoinGlyphColors._(tint, null, _lbtcDrop),
    // The green disc behind the ₮.
    Asset.usdt => CoinGlyphColors._(tint, _usdtDisc, null),
    // The dark bar of the D.
    Asset.depix => CoinGlyphColors._(tint, null, _depixBar),
  };

  static const _btcDisc = 0xFFF7931A;
  static const _lbtcDrop = 0xFF46BEAE;
  static const _usdtDisc = 0xFF26A17B;
  static const _depixBar = 0xFF366378;

  /// The color of [asset], taken from its icon, for a coin in the colors of
  /// the asset. The DePix coin takes the dark bar of its D: the light teal
  /// of its icon would read as the L-BTC drop.
  static Color colorOf(Asset asset) => Color(switch (asset) {
    Asset.btc => _btcDisc,
    Asset.lbtc => _lbtcDrop,
    Asset.usdt => _usdtDisc,
    Asset.depix => _depixBar,
  });

  /// Size of the icon on the face, as a share of the coin diameter. The
  /// symbols fill their icons by different amounts, so each gets its own
  /// share to look the same size.
  static double scaleOf(Asset asset) => switch (asset) {
    Asset.btc => 0.92,
    Asset.lbtc => 0.58,
    Asset.usdt => 0.9,
    Asset.depix => 0.52,
  };

  final Color tint;
  final int? _clear;
  final int? _dimmed;

  @override
  Color substitute(
    String? id,
    String elementName,
    String attributeName,
    Color color,
  ) {
    final argb = color.toARGB32();
    if (argb == _clear) return Colors.transparent;
    if (argb == _dimmed) return tint.withValues(alpha: tint.a * 0.45);
    return tint;
  }

  @override
  bool operator ==(Object other) =>
      other is CoinGlyphColors &&
      other.tint == tint &&
      other._clear == _clear &&
      other._dimmed == _dimmed;

  @override
  int get hashCode => Object.hash(tint, _clear, _dimmed);
}

/// Draws a two-tone glyph in one [tint].
///
/// The two-tone glyphs, such as the level emblems in `assets/icons/level`,
/// draw their faces in light in white and their faces in shade in gray.
/// The faces in light take [tint] and the faces in shade a dimmed [tint],
/// so the glyph keeps its relief.
@immutable
class TwoToneGlyphColors extends ColorMapper {
  const TwoToneGlyphColors(this.tint);

  final Color tint;

  /// The gray of the faces in shade in the glyph files.
  static const _shade = 0xFF8E8E93;

  @override
  Color substitute(
    String? id,
    String elementName,
    String attributeName,
    Color color,
  ) {
    if (color.toARGB32() == _shade) return tint.withValues(alpha: tint.a * 0.5);
    return tint;
  }

  @override
  bool operator ==(Object other) =>
      other is TwoToneGlyphColors && other.tint == tint;

  @override
  int get hashCode => tint.hashCode;
}
