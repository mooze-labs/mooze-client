import 'package:mooze_mobile/features/pix/shared/cpf/domain/cpf_validator.dart';

class FavoritePayer {
  final int? id;
  final String label;

  /// Unmasked taxpayer id digits — CPF (11) or CNPJ (14).
  final String cpf;

  const FavoritePayer({this.id, required this.label, required this.cpf});

  /// CPF/CNPJ formatted for display.
  String get maskedCpf => formatCpfCnpj(cpf);

  FavoritePayer copyWith({int? id, String? label, String? cpf}) => FavoritePayer(
    id: id ?? this.id,
    label: label ?? this.label,
    cpf: cpf ?? this.cpf,
  );

  @override
  bool operator ==(Object other) =>
      other is FavoritePayer &&
      other.id == id &&
      other.label == label &&
      other.cpf == cpf;

  @override
  int get hashCode => Object.hash(id, label, cpf);
}
