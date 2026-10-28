/// Pix key types recognised by the Brazilian Pix standard.
enum PixKeyType { cpf, cnpj, phone, email, random }

/// A Pix key that belongs to the current user or to a recipient.
///
/// [value] holds the raw key. Screens render [masked] instead, so a full
/// document or phone number never reaches the UI by accident.
class PixKey {
  final String id;
  final PixKeyType type;
  final String value;

  /// Free-form label chosen by the owner, or null when the key has none.
  final String? label;

  final DateTime createdAt;

  const PixKey({
    required this.id,
    required this.type,
    required this.value,
    required this.createdAt,
    this.label,
  });

  /// Partially hidden form of [value], safe to show on screen.
  String get masked => maskPixKey(type, value);
}

/// Hides the identifying part of a Pix key.
///
/// Each key type keeps a different visible tail so the owner still recognises
/// the key without the screen exposing the whole document or phone number.
String maskPixKey(PixKeyType type, String value) {
  switch (type) {
    case PixKeyType.cpf:
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length != 11) return _maskGeneric(value);
      return '***.${digits.substring(3, 6)}.${digits.substring(6, 9)}-**';
    case PixKeyType.cnpj:
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length != 14) return _maskGeneric(value);
      return '**.${digits.substring(2, 5)}.${digits.substring(5, 8)}/****-**';
    case PixKeyType.phone:
      final digits = value.replaceAll(RegExp(r'[^0-9]'), '');
      if (digits.length < 4) return _maskGeneric(value);
      return '(**) *****-${digits.substring(digits.length - 4)}';
    case PixKeyType.email:
      final at = value.indexOf('@');
      if (at <= 0) return _maskGeneric(value);
      final name = value.substring(0, at);
      final domain = value.substring(at);
      final head = name.substring(0, 1);
      return '$head${'*' * (name.length - 1).clamp(1, 6)}$domain';
    case PixKeyType.random:
      if (value.length <= 12) return _maskGeneric(value);
      return '${value.substring(0, 8)}…${value.substring(value.length - 4)}';
  }
}

String _maskGeneric(String value) {
  if (value.length <= 4) return '****';
  return '${'*' * (value.length - 4)}${value.substring(value.length - 4)}';
}
