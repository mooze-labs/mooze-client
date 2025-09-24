import 'package:mooze_mobile/features/merchant/models/product.dart';
import 'package:mooze_mobile/shared/utils/result.dart';

abstract class ProductRepository {
  Future<Result<int>> createProduct(ProductEntity product);
  Future<Result<List<ProductEntity>>> getAllProducts();
  Future<Result<ProductEntity?>> getProductById(int id);
  Future<Result<bool>> updateProduct(ProductEntity product);
  Future<Result<bool>> deleteProduct(int id);
}
