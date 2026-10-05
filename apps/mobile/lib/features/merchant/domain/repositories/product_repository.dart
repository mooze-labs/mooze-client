import 'package:mooze_mobile/features/merchant/domain/entities/product_entity.dart';
import 'package:mooze_mobile/shared/utils/result.dart';

abstract class ProductRepository {
  /// Creates a new product in the database
  /// Returns: Result<int> with the new product's ID
  Future<Result<int>> createProduct(ProductEntity product);

  /// Retrieves all products from the database
  /// Returns: Result<List<ProductEntity>> with all products
  Future<Result<List<ProductEntity>>> getAllProducts();

  /// Retrieves a specific product by its ID
  /// Returns: Result<ProductEntity?> with the product or null if not found
  Future<Result<ProductEntity?>> getProductById(int id);

  /// Updates an existing product
  /// Returns: Result<bool> indicating success or failure
  Future<Result<bool>> updateProduct(ProductEntity product);

  /// Deletes a product by its ID
  /// Returns: Result<bool> indicating success or failure
  Future<Result<bool>> deleteProduct(int id);
}
