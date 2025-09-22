class SendMethod {
  final String id;
  final String name;
  final String iconAsset;

  SendMethod({required this.id, required this.name, required this.iconAsset});
}

final List<SendMethod> sendMethods = [
  SendMethod(
    id: 'telegram',
    name: 'Telegram',
    iconAsset: 'assets/icons/contacts/telegram.svg',
  ),
  SendMethod(
    id: 'whatsapp',
    name: 'WhatsApp',
    iconAsset: 'assets/icons/contacts/whatsapp.svg',
  ),
  SendMethod(
    id: 'sms',
    name: 'SMS',
    iconAsset: 'assets/icons/contacts/sms.svg',
  ),
];
