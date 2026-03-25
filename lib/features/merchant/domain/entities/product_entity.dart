/// Product Entity (Domain Layer)
///
/// Properties:
/// - [id]: Optional unique identifier (null for new products)
/// - [name]: Product name
/// - [price]: Product price in Brazilian Reais (BRL)
/// - [createdAt]: Timestamp when the product was created
class ProductEntity {
  final int? id;
  final String name;
  final double price;
  final DateTime createdAt;

  const ProductEntity({
    this.id,
    required this.name,
    required this.price,
    required this.createdAt,
  });

  /// Validates if the product meets business rules
  /// Returns true if name is not empty and price > 0
  bool get isValid => name.isNotEmpty && price > 0;

  /// Validates the product and returns an error message if invalid
  ///
  /// Returns:
  /// - null if valid
  /// - Error message string if validation fails
  String? validate() {
    if (name.isEmpty) {
      return 'Nome do produto não pode ser vazio'; // Product name cannot be empty
    }
    if (price <= 0) {
      return 'Preço deve ser maior que zero'; // Price must be greater than zero
    }
    return null;
  }

  ProductEntity copyWith({
    int? id,
    String? name,
    double? price,
    DateTime? createdAt,
  }) {
    return ProductEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      price: price ?? this.price,
      createdAt: createdAt ?? this.createdAt,
    );
  }

  @override
  String toString() {
    return 'ProductEntity(id: $id, name: $name, price: $price, createdAt: $createdAt)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is ProductEntity &&
        other.id == id &&
        other.name == name &&
        other.price == price &&
        other.createdAt == createdAt;
  }

  @override
  int get hashCode {
    return id.hashCode ^ name.hashCode ^ price.hashCode ^ createdAt.hashCode;
  }
}
