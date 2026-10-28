import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_key.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_payment_link.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_recipient.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_send_method.dart';
import 'package:mooze_mobile/features/pix/hub/domain/entities/pix_transaction.dart';
import 'package:mooze_mobile/features/pix/hub/domain/validation/pix_br_code.dart';

/// Every fictional record used by the Pix hub.
///
/// The hub has no Pix sending, key registry or recipient lookup service, so
/// these records stand in for them. Keeping the data in one place means a real
/// integration only has to replace `DemoPixHubRepository`.
///
/// All names, documents and keys below are invented. Dates are relative to the
/// moment the dataset is read, so the lists always look recent.
class PixDemoDataset {
  const PixDemoDataset._();

  /// Name shown on charges and QR Codes created by the demonstration flows.
  static const String demoMerchantName = 'MOOZE DEMO';

  /// City shown on the generated BR Codes.
  static const String demoMerchantCity = 'SAO PAULO';

  /// Host used by the demonstration payment links.
  ///
  /// `invalid` is a reserved top-level domain, so the address can never
  /// resolve to a real checkout page.
  static const String demoLinkHost = 'https://demo.mooze.invalid/pay';

  /// Prefix of every demonstration reference, so no screen can pass as an
  /// official receipt.
  static const String referencePrefix = 'DEMO';

  static DateTime _ago({int days = 0, int hours = 0, int minutes = 0}) {
    return DateTime.now().subtract(
      Duration(days: days, hours: hours, minutes: minutes),
    );
  }

  /// Pix keys presented as belonging to the current user.
  static List<PixKey> keys() => [
    PixKey(
      id: 'demo-key-email',
      type: PixKeyType.email,
      value: 'exemplo.demo@mooze.invalid',
      label: 'E-mail',
      createdAt: _ago(days: 212),
    ),
    PixKey(
      id: 'demo-key-phone',
      type: PixKeyType.phone,
      value: '+5511999990000',
      label: 'Celular',
      createdAt: _ago(days: 180),
    ),
    PixKey(
      id: 'demo-key-random',
      type: PixKeyType.random,
      value: '7b1f4c2e-5a3d-4c8b-9f10-2d6e8a4b7c91',
      createdAt: _ago(days: 64),
    ),
  ];

  /// Recipients the user paid recently.
  static List<PixRecipient> recipients() => [
    PixRecipient(
      id: 'demo-rcp-ana',
      name: 'Ana Demonstracao',
      maskedDocument: '***.412.780-**',
      institution: 'Banco Exemplo S.A.',
      keyType: PixKeyType.email,
      keyValue: 'ana.demo@exemplo.invalid',
      lastPaidAt: _ago(days: 1, hours: 3),
    ),
    PixRecipient(
      id: 'demo-rcp-bruno',
      name: 'Bruno Ficticio',
      maskedDocument: '***.908.311-**',
      institution: 'Instituicao Demo',
      keyType: PixKeyType.phone,
      keyValue: '+5521988887777',
      lastPaidAt: _ago(days: 4),
    ),
    PixRecipient(
      id: 'demo-rcp-carla',
      name: 'Carla Exemplo',
      maskedDocument: '***.225.604-**',
      institution: 'Banco Exemplo S.A.',
      keyType: PixKeyType.random,
      keyValue: 'c0ffee11-2233-4455-6677-8899aabbccdd',
      lastPaidAt: _ago(days: 9),
    ),
    PixRecipient(
      id: 'demo-rcp-mercado',
      name: 'Mercado Demo Ltda',
      maskedDocument: '**.776.540/****-**',
      institution: 'Banco Teste',
      keyType: PixKeyType.cnpj,
      keyValue: '11776540000199',
      lastPaidAt: _ago(days: 15),
    ),
  ];

  /// Pix movements shown by the history screen.
  static List<PixTransaction> transactions() => [
    PixTransaction(
      id: 'demo-tx-01',
      kind: PixTransactionKind.sent,
      status: PixTransactionStatus.completed,
      counterpartyName: 'Ana Demonstracao',
      amountInCents: 8450,
      createdAt: _ago(days: 1, hours: 3),
      description: 'Almoco',
      method: PixSendMethod.recent,
      reference: '$referencePrefix-20A4F1',
    ),
    PixTransaction(
      id: 'demo-tx-02',
      kind: PixTransactionKind.received,
      status: PixTransactionStatus.completed,
      counterpartyName: 'Bruno Ficticio',
      amountInCents: 25000,
      createdAt: _ago(days: 2, hours: 6),
      reference: '$referencePrefix-77C3BB',
    ),
    PixTransaction(
      id: 'demo-tx-03',
      kind: PixTransactionKind.deposit,
      status: PixTransactionStatus.completed,
      counterpartyName: 'Deposito na carteira',
      amountInCents: 100000,
      createdAt: _ago(days: 3),
      reference: '$referencePrefix-91DE02',
    ),
    PixTransaction(
      id: 'demo-tx-04',
      kind: PixTransactionKind.paymentLink,
      status: PixTransactionStatus.completed,
      counterpartyName: 'Link: consultoria',
      amountInCents: 45000,
      createdAt: _ago(days: 5, hours: 2),
      reference: '$referencePrefix-5B10AC',
    ),
    PixTransaction(
      id: 'demo-tx-05',
      kind: PixTransactionKind.sent,
      status: PixTransactionStatus.pending,
      counterpartyName: 'Mercado Demo Ltda',
      amountInCents: 13790,
      createdAt: _ago(days: 6),
      method: PixSendMethod.qrCode,
      reference: '$referencePrefix-3F8821',
    ),
    PixTransaction(
      id: 'demo-tx-06',
      kind: PixTransactionKind.sent,
      status: PixTransactionStatus.failed,
      counterpartyName: 'Carla Exemplo',
      amountInCents: 6000,
      createdAt: _ago(days: 8, hours: 5),
      description: 'Rateio',
      method: PixSendMethod.key,
      reference: '$referencePrefix-A0C7D4',
    ),
    PixTransaction(
      id: 'demo-tx-07',
      kind: PixTransactionKind.received,
      status: PixTransactionStatus.completed,
      counterpartyName: 'Ana Demonstracao',
      amountInCents: 3200,
      createdAt: _ago(days: 12),
      reference: '$referencePrefix-6612EF',
    ),
    PixTransaction(
      id: 'demo-tx-08',
      kind: PixTransactionKind.deposit,
      status: PixTransactionStatus.completed,
      counterpartyName: 'Deposito na carteira',
      amountInCents: 50000,
      createdAt: _ago(days: 18),
      reference: '$referencePrefix-D4471A',
    ),
  ];

  /// Payment links owned by the user.
  static List<PixPaymentLink> paymentLinks() => [
    PixPaymentLink(
      id: 'demo-link-01',
      url: '$demoLinkHost/7f3a91',
      reference: 'Consultoria - marco',
      amountInCents: 45000,
      status: PixPaymentLinkStatus.paid,
      createdAt: _ago(days: 6),
      paidAt: _ago(days: 5, hours: 2),
      singleUse: true,
    ),
    PixPaymentLink(
      id: 'demo-link-02',
      url: '$demoLinkHost/b21c08',
      reference: 'Mensalidade do clube',
      amountInCents: 12000,
      status: PixPaymentLinkStatus.pending,
      createdAt: _ago(days: 2),
      singleUse: false,
    ),
    PixPaymentLink(
      id: 'demo-link-03',
      url: '$demoLinkHost/5de4a7',
      reference: 'Doacao livre',
      amountInCents: null,
      status: PixPaymentLinkStatus.pending,
      createdAt: _ago(days: 1, hours: 8),
      singleUse: false,
    ),
  ];

  /// A ready-made Copy and Paste code, used by the scan and paste screens so
  /// the flows can be exercised without a real charge.
  static String sampleBrCode() => brCodeFor(
    pixKey: 'ana.demo@exemplo.invalid',
    amountInCents: 8450,
    transactionId: '${referencePrefix}SAMPLE',
    description: 'Cobranca de demonstracao',
  );

  /// Builds the Copy and Paste payload of a demonstration charge.
  static String brCodeFor({
    required String pixKey,
    int? amountInCents,
    String? transactionId,
    String? description,
  }) {
    return PixBrCodeParser.build(
      pixKey: pixKey,
      merchantName: demoMerchantName,
      merchantCity: demoMerchantCity,
      amountInCents: amountInCents,
      transactionId: transactionId,
      description: description,
    );
  }
}
