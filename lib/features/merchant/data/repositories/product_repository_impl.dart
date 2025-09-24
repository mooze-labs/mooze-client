import 'package:drift/drift.dart';
import 'package:mooze_mobile/database/database.dart';
import 'package:mooze_mobile/features/merchant/domain/repositories/product_repository.dart';
import 'package:mooze_mobile/features/merchant/models/product.dart';
import 'package:mooze_mobile/shared/utils/result.dart';

class ProductRepositoryImpl implements ProductRepository {
  final AppDatabase _database;

  ProductRepositoryImpl(this._database);

  @override
  Future<Result<int>> createProduct(ProductEntity product) async {
    try {
      final companion = ProductsCompanion(
        name: Value(product.name),
        price: Value(product.price),
        createdAt: Value(product.createdAt),
      );

      final id = await _database.into(_database.products).insert(companion);
      return Success(id);
    } catch (e) {
      return Failure('Erro ao criar produto: ${e.toString()}', e as Exception?);
    }
  }

  @override
  Future<Result<List<ProductEntity>>> getAllProducts() async {
    try {
      final productsData = await _database.select(_database.products).get();

      final products =
          productsData.map((productData) {
            return ProductEntity(
              id: productData.id,
              name: productData.name,
              price: productData.price,
              createdAt: productData.createdAt,
            );
          }).toList();

      return Success(products);
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
      final query = _database.select(_database.products)
        ..where((p) => p.id.equals(id));

      final productData = await query.getSingleOrNull();

      if (productData == null) {
        return const Success(null);
      }

      final product = ProductEntity(
        id: productData.id,
        name: productData.name,
        price: productData.price,
        createdAt: productData.createdAt,
      );

      return Success(product);
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
      if (product.id == null) {
        return const Failure('ID do produto é obrigatório para atualização');
      }

      final companion = ProductsCompanion(
        id: Value(product.id!),
        name: Value(product.name),
        price: Value(product.price),
        createdAt: Value(product.createdAt),
      );

      final success = await _database
          .update(_database.products)
          .replace(companion);
      return Success(success);
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
      final rowsAffected =
          await (_database.delete(_database.products)
            ..where((p) => p.id.equals(id))).go();

      return Success(rowsAffected > 0);
    } catch (e) {
      return Failure(
        'Erro ao deletar produto: ${e.toString()}',
        e as Exception?,
      );
    }
  }
}
