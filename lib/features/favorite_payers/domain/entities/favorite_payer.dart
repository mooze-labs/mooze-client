class FavoritePayer {
  final int? id;
  final String label;
  final String cpf;

  const FavoritePayer({this.id, required this.label, required this.cpf});

  String get maskedCpf {
    if (cpf.length != 11) return cpf;
    return '${cpf.substring(0, 3)}.${cpf.substring(3, 6)}.'
        '${cpf.substring(6, 9)}-${cpf.substring(9)}';
  }

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
