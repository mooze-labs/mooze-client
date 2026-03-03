import 'package:mooze_mobile/features/merchant/domain/entities/product_entity.dart';
import 'package:mooze_mobile/features/merchant/domain/repositories/product_repository.dart';
import 'package:mooze_mobile/shared/utils/result.dart';

/// Use Case: Get All Products
///
/// Encapsulates the business logic for retrieving all products.
/// Returns the complete list of products stored in the database.
///
/// Usage:
/// Used in the merchant mode "Items" tab to display all available
/// products that can be added to the cart.
class GetAllProductsUseCase {
  final ProductRepository _repository;

  const GetAllProductsUseCase(this._repository);

  /// Retrieves all products from the database
  Future<Result<List<ProductEntity>>> call() async {
    return await _repository.getAllProducts();
  }
}
