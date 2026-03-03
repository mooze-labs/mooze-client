import 'package:mooze_mobile/features/merchant/domain/entities/product_entity.dart';
import 'package:mooze_mobile/shared/utils/result.dart';

/// Product Data Source Contract (Infrastructure Layer)
/// 
abstract class ProductDataSource {
  /// Creates a new product and returns its generated ID
  Future<Result<int>> create(ProductEntity product);
  
  /// Retrieves all products
  Future<Result<List<ProductEntity>>> getAll();
  
  /// Retrieves a single product by ID (returns null if not found)
  Future<Result<ProductEntity?>> getById(int id);
  
  /// Updates an existing product (returns true if successful)
  Future<Result<bool>> update(ProductEntity product);
  
  /// Deletes a product by ID (returns true if found and deleted)
  Future<Result<bool>> delete(int id);
}
