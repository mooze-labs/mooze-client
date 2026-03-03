/// Cart Item Entity (Domain Layer)
/// 
/// Properties:
/// - [productId]: Unique identifier for the product
/// - [name]: Product name
/// - [price]: Product price
/// - [quantity]: Quantity in cart
class CartItemEntity {
  final int productId;
  final String name;
  final double price;
  final int quantity;

  const CartItemEntity({
    required this.productId,
    required this.name,
    required this.price,
    required this.quantity,
  });

  /// Business rule: Calculate the total price for this item
  /// Returns: [price] * [quantity]
  double get total => price * quantity;

  /// Validates if the cart item meets business rules
  /// Returns true if quantity > 0, price > 0, and name is not empty
  bool get isValid => quantity > 0 && price > 0 && name.isNotEmpty;

  /// Validates the cart item and returns an error message if invalid
  /// 
  /// Returns:
  /// - null if valid
  /// - Error message string if validation fails
  String? validate() {
    if (name.isEmpty) {
      return 'name do item não pode ser vazio'; // Item name cannot be empty
    }
    if (price <= 0) {
      return 'Preço deve ser maior que zero'; // Price must be greater than zero
    }
    if (quantity <= 0) {
      return 'quantity deve ser maior que zero'; // Quantity must be greater than zero
    }
    return null;
  }

  /// Creates a copy of this cart item with the given fields replaced
  /// 
  /// This method is useful for immutability - instead of modifying the object,
  /// we create a new one with updated values
  CartItemEntity copyWith({
    int? productId,
    String? name,
    double? price,
    int? quantity,
  }) {
    return CartItemEntity(
      productId: productId ?? this.productId,
      name: name ?? this.name,
      price: price ?? this.price,
      quantity: quantity ?? this.quantity,
    );
  }

  @override
  String toString() {
    return 'CartItemEntity(productId: $productId, name: $name, price: $price, quantity: $quantity, total: $total)';
  }

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is CartItemEntity &&
        other.productId == productId &&
        other.name == name &&
        other.price == price &&
        other.quantity == quantity;
  }

  @override
  int get hashCode {
    return productId.hashCode ^
        name.hashCode ^
        price.hashCode ^
        quantity.hashCode;
  }
}
