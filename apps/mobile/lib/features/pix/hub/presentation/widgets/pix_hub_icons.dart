import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_key.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_send_method.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_transaction.dart';
import 'package:mooze_mobile/features/pix/shared/presentation/widgets/pix_icons.dart';

/// Icons of the Pix hub enums.
///
/// Like the labels in `pix_hub_labels.dart`, the mapping lives here so each
/// screen does not repeat the same switch.

PixIconData pixKeyTypeIcon(PixKeyType type) => switch (type) {
  PixKeyType.cpf => PixIcons.idCard,
  PixKeyType.cnpj => PixIcons.company,
  PixKeyType.phone => PixIcons.phone,
  PixKeyType.email => PixIcons.email,
  PixKeyType.random => PixIcons.randomKey,
};

PixIconData pixTransactionKindIcon(PixTransactionKind kind) => switch (kind) {
  PixTransactionKind.sent => PixIcons.send,
  PixTransactionKind.received => PixIcons.receive,
  PixTransactionKind.deposit => PixIcons.deposit,
  PixTransactionKind.paymentLink => PixIcons.link,
};

PixIconData pixSendMethodIcon(PixSendMethod method) => switch (method) {
  PixSendMethod.key => PixIcons.key,
  PixSendMethod.qrCode => PixIcons.scan,
  PixSendMethod.copyPaste => PixIcons.paste,
  PixSendMethod.recent => PixIcons.history,
};
