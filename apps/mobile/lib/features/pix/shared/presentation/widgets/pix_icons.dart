import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

/// An SVG icon of the Pix flow. It is the counterpart of [IconData].
@immutable
class PixIconData {
  const PixIconData(this.assetName);

  /// Path of the SVG asset.
  final String assetName;

  @override
  bool operator ==(Object other) =>
      other is PixIconData && other.assetName == assetName;

  @override
  int get hashCode => assetName.hashCode;

  @override
  String toString() => 'PixIconData($assetName)';
}

/// The icons of the Pix flow.
///
/// Every icon comes from Lucide (ISC License, https://lucide.dev), the icon
/// set of the Mooze web app. The SVG files use a 24 pt grid and a 1.75 pt
/// round stroke, so all Pix icons share one line weight. Do not mix them
/// with filled icons on the same screen.
abstract final class PixIcons {
  static const _dir = 'assets/icons/pix';

  // Money movement.
  static const send = PixIconData('$_dir/arrow_up_right.svg');
  static const receive = PixIconData('$_dir/arrow_down_left.svg');
  static const deposit = PixIconData('$_dir/wallet.svg');
  static const arrowDown = PixIconData('$_dir/arrow_down.svg');
  static const arrowRight = PixIconData('$_dir/arrow_right.svg');
  static const exchange = PixIconData('$_dir/arrow_left_right.svg');
  static const amount = PixIconData('$_dir/banknote.svg');
  static const bitcoin = PixIconData('$_dir/bitcoin.svg');
  static const bank = PixIconData('$_dir/landmark.svg');
  static const trendingUp = PixIconData('$_dir/trending_up.svg');
  static const percent = PixIconData('$_dir/percent.svg');

  // Pix methods and keys.
  static const key = PixIconData('$_dir/key_round.svg');
  static const qrCode = PixIconData('$_dir/qr_code.svg');
  static const scan = PixIconData('$_dir/scan_qr_code.svg');
  static const paste = PixIconData('$_dir/clipboard_paste.svg');
  static const link = PixIconData('$_dir/link.svg');
  static const linkOff = PixIconData('$_dir/unlink.svg');
  static const idCard = PixIconData('$_dir/id_card.svg');
  static const company = PixIconData('$_dir/building.svg');
  static const phone = PixIconData('$_dir/smartphone.svg');
  static const email = PixIconData('$_dir/at_sign.svg');
  static const mail = PixIconData('$_dir/mail.svg');
  static const randomKey = PixIconData('$_dir/shuffle.svg');

  // People.
  static const person = PixIconData('$_dir/user_round.svg');
  static const people = PixIconData('$_dir/users_round.svg');
  static const personAdd = PixIconData('$_dir/user_round_plus.svg');

  // Actions.
  static const copy = PixIconData('$_dir/copy.svg');
  static const share = PixIconData('$_dir/share.svg');
  static const add = PixIconData('$_dir/plus.svg');
  static const delete = PixIconData('$_dir/trash.svg');
  static const close = PixIconData('$_dir/x.svg');
  static const check = PixIconData('$_dir/check.svg');
  static const refresh = PixIconData('$_dir/refresh_cw.svg');
  static const restart = PixIconData('$_dir/rotate_ccw.svg');
  static const externalLink = PixIconData('$_dir/external_link.svg');
  static const chevronRight = PixIconData('$_dir/chevron_right.svg');
  static const chevronDown = PixIconData('$_dir/chevron_down.svg');

  // Records and time.
  static const history = PixIconData('$_dir/history.svg');
  static const receipt = PixIconData('$_dir/receipt_text.svg');
  static const document = PixIconData('$_dir/file_text.svg');
  static const inbox = PixIconData('$_dir/inbox.svg');
  static const calendar = PixIconData('$_dir/calendar.svg');
  static const clock = PixIconData('$_dir/clock.svg');
  static const pending = PixIconData('$_dir/hourglass.svg');
  static const tag = PixIconData('$_dir/tag.svg');
  static const gift = PixIconData('$_dir/gift.svg');

  // Status.
  static const success = PixIconData('$_dir/circle_check.svg');
  static const failure = PixIconData('$_dir/circle_x.svg');
  static const error = PixIconData('$_dir/circle_alert.svg');
  static const warning = PixIconData('$_dir/triangle_alert.svg');
  static const info = PixIconData('$_dir/info.svg');
  static const help = PixIconData('$_dir/circle_help.svg');
  static const offline = PixIconData('$_dir/cloud_off.svg');
  static const cameraOff = PixIconData('$_dir/camera_off.svg');
  static const celebrate = PixIconData('$_dir/party_popper.svg');

  // Trust and levels.
  static const shield = PixIconData('$_dir/shield.svg');
  static const shieldCheck = PixIconData('$_dir/shield_check.svg');
  static const shieldAlert = PixIconData('$_dir/shield_alert.svg');
  static const lock = PixIconData('$_dir/lock.svg');
  static const level = PixIconData('$_dir/award.svg');
  static const star = PixIconData('$_dir/star.svg');
  static const fast = PixIconData('$_dir/zap.svg');
  static const demo = PixIconData('$_dir/flask_conical.svg');
}

/// Draws a [PixIconData], like [Icon] draws an [IconData].
///
/// The size and the color come from the nearest [IconTheme] when they are
/// null. Without a [semanticLabel], screen readers skip the icon, as they
/// skip an [Icon].
class PixIcon extends StatelessWidget {
  const PixIcon(
    this.icon, {
    super.key,
    this.size,
    this.color,
    this.semanticLabel,
  });

  final PixIconData icon;
  final double? size;
  final Color? color;
  final String? semanticLabel;

  @override
  Widget build(BuildContext context) {
    final iconTheme = IconTheme.of(context);
    final size = this.size ?? iconTheme.size ?? 24;
    final color =
        this.color ??
        iconTheme.color ??
        DefaultTextStyle.of(context).style.color;
    return SvgPicture.asset(
      icon.assetName,
      width: size,
      height: size,
      colorFilter: color == null
          ? null
          : ColorFilter.mode(color, BlendMode.srcIn),
      semanticsLabel: semanticLabel,
      excludeFromSemantics: semanticLabel == null,
    );
  }
}
