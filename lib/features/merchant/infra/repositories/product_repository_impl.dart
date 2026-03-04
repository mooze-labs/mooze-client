import 'package:mooze_mobile/features/merchant/domain/entities/product_entity.dart';
import 'package:mooze_mobile/features/merchant/domain/repositories/product_repository.dart';
import 'package:mooze_mobile/features/merchant/infra/datasources/product_datasource.dart';
import 'package:mooze_mobile/shared/utils/result.dart';

/// Product Repository Implementation (Infrastructure Layer)
///
/// Adapts data from the DataSource (database) to the format expected by the Domain layer.
/// This layer acts as a bridge between the domain and external data sources,
/// handling data transformation and error handling.
///
/// Responsibilities:
/// - Convert database operations to domain Results
/// - Handle exceptions and convert them to Failure results
/// - Delegate actual data access to the DataSource
class ProductRepositoryImpl implements ProductRepository {
  final ProductDataSource _dataSource;

  const ProductRepositoryImpl(this._dataSource);

  @override
  Future<Result<int>> createProduct(ProductEntity product) async {
    try {
      return await _dataSource.create(product);
    } catch (e) {
      // Convert exceptions to domain Failures
      return Failure('Erro ao criar produto: ${e.toString()}', e as Exception?);
    }
  }

  @override
  Future<Result<List<ProductEntity>>> getAllProducts() async {
    try {
      return await _dataSource.getAll();
    } catch (e) {
      return Failure(
        'Erro ao buscar produtos: ${e.toString()}',
        e as Exception?,
      );
    }
  }

  @override
  Future<Result<ProductEntity?>> getProductById(int id) async {
    try {
      return await _dataSource.getById(id);
    } catch (e) {
      return Failure(
        'Erro ao buscar produto: ${e.toString()}',
        e as Exception?,
      );
    }
  }

  @override
  Future<Result<bool>> updateProduct(ProductEntity product) async {
    try {
      return await _dataSource.update(product);
    } catch (e) {
      return Failure(
        'Erro ao atualizar produto: ${e.toString()}',
        e as Exception?,
      );
    }
  }

  @override
  Future<Result<bool>> deleteProduct(int id) async {
    try {
      return await _dataSource.delete(id);
    } catch (e) {
      return Failure(
        'Erro ao deletar produto: ${e.toString()}',
        e as Exception?,
      );
    }
  }
}
