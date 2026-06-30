import 'package:mooze_mobile/features/merchant/domain/repositories/product_repository.dart';
import 'package:mooze_mobile/shared/utils/result.dart';

/// Use Case: Delete Product
///
/// Business Rules:
/// - Product ID must be positive (greater than 0)
/// - Returns true if product was deleted, false if not found
class DeleteProductUseCase {
  final ProductRepository _repository;

  const DeleteProductUseCase(this._repository);

  /// Deletes a product by ID after validation
  ///
  /// Parameters:
  ///   - id: Product ID to delete (must be > 0)
  /// Returns: Result<bool> - true if deleted, false if not found, or Failure with error
  Future<Result<bool>> call(int id) async {
    // Business rule validation: ID must be positive
    if (id <= 0) {
      return const Failure('Invalid product ID');
    }

    // Delegate deletion to repository
    return await _repository.deleteProduct(id);
  }
}
