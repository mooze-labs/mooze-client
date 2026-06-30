import 'package:mooze_mobile/features/merchant/domain/entities/product_entity.dart';
import 'package:mooze_mobile/features/merchant/domain/repositories/product_repository.dart';
import 'package:mooze_mobile/shared/utils/result.dart';

/// Use Case: Update Product

class UpdateProductUseCase {
  final ProductRepository _repository;

  const UpdateProductUseCase(this._repository);

  Future<Result<bool>> call(ProductEntity product) async {
    // Business rule: Product must have an ID for updates
    if (product.id == null) {
      return const Failure('Product ID is required for update');
    }

    // Validate product data
    final validationError = product.validate();
    if (validationError != null) {
      return Failure(validationError);
    }

    // Delegate persistence to repository
    return await _repository.updateProduct(product);
  }
}
