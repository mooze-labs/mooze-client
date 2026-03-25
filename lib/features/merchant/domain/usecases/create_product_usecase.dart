import 'package:mooze_mobile/features/merchant/domain/entities/product_entity.dart';
import 'package:mooze_mobile/features/merchant/domain/repositories/product_repository.dart';
import 'package:mooze_mobile/shared/utils/result.dart';

/// Use Case: Create Product
///
/// Encapsulates the business logic for creating a new product.
/// Validates the product before persisting to ensure data integrity.
///
/// Business Rules:
/// - Product name cannot be empty
/// - Product price must be greater than zero
/// - Validation occurs before database insertion
///
/// Returns the generated product ID on success.
class CreateProductUseCase {
  final ProductRepository _repository;

  const CreateProductUseCase(this._repository);

  /// Creates a new product after validation
  ///
  /// Parameters:
  ///   - product: ProductEntity to create (without ID)
  /// Returns: Result<int> - the generated product ID, or Failure with error message
  Future<Result<int>> call(ProductEntity product) async {
    // Business rule validation
    final validationError = product.validate();
    if (validationError != null) {
      return Failure(validationError);
    }

    // Delegate persistence to repository
    return await _repository.createProduct(product);
  }
}
