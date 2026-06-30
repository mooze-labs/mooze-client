import 'package:drift/drift.dart';
import 'package:mooze_mobile/database/database.dart';
import 'package:mooze_mobile/features/merchant/domain/entities/product_entity.dart';
import 'package:mooze_mobile/features/merchant/infra/datasources/product_datasource.dart';
import 'package:mooze_mobile/shared/utils/result.dart';

/// Product Drift Data Source Implementation (External Layer)
///
/// Concrete implementation using Drift ORM for local database storage.
/// Manages product persistence in a type-safe SQLite database.
///
/// To switch storage (e.g., to Firebase, Hive, or REST API),
/// simply create a new implementation of ProductDataSource
/// and update the provider - no other layers need to change.
///
class ProductDriftDataSource implements ProductDataSource {
  final AppDatabase _database;

  const ProductDriftDataSource(this._database);

  @override
  Future<Result<int>> create(ProductEntity product) async {
    try {
      // Convert ProductEntity to Drift companion for insertion
      final companion = ProductsCompanion(
        name: Value(product.name),
        price: Value(product.price),
        createdAt: Value(product.createdAt),
      );

      // Insert and get auto-generated ID
      final id = await _database.into(_database.products).insert(companion);
      return Success(id);
    } catch (e) {
      return Failure(
        'Error creating product: ${e.toString()}',
        e as Exception?,
      );
    }
  }

  @override
  Future<Result<List<ProductEntity>>> getAll() async {
    try {
      // Query all products from database
      final productsData = await _database.select(_database.products).get();

      // Convert Drift data models to domain entities
      final products =
          productsData
              .map(
                (productData) => ProductEntity(
                  id: productData.id,
                  name: productData.name,
                  price: productData.price,
                  createdAt: productData.createdAt,
                ),
              )
              .toList();

      return Success(products);
    } catch (e) {
      return Failure(
        'Error fetching products: ${e.toString()}',
        e as Exception?,
      );
    }
  }

  @override
  Future<Result<ProductEntity?>> getById(int id) async {
    try {
      // Build query with WHERE clause
      final query = _database.select(_database.products)
        ..where((p) => p.id.equals(id));

      // Get single result or null if not found
      final productData = await query.getSingleOrNull();

      if (productData == null) {
        return const Success(null);
      }

      // Convert to domain entity
      final product = ProductEntity(
        id: productData.id,
        name: productData.name,
        price: productData.price,
        createdAt: productData.createdAt,
      );

      return Success(product);
    } catch (e) {
      return Failure(
        'Error fetching product: ${e.toString()}',
        e as Exception?,
      );
    }
  }

  @override
  Future<Result<bool>> update(ProductEntity product) async {
    try {
      if (product.id == null) {
        return const Failure('Product ID is required for update');
      }

      // Convert ProductEntity to Drift companion for update
      final companion = ProductsCompanion(
        id: Value(product.id!),
        name: Value(product.name),
        price: Value(product.price),
        createdAt: Value(product.createdAt),
      );

      // Replace existing row (returns true if successful)
      final success = await _database
          .update(_database.products)
          .replace(companion);
      return Success(success);
    } catch (e) {
      return Failure(
        'Error updating product: ${e.toString()}',
        e as Exception?,
      );
    }
  }

  @override
  Future<Result<bool>> delete(int id) async {
    try {
      // Delete with WHERE clause and get affected rows count
      final rowsAffected =
          await (_database.delete(_database.products)
            ..where((p) => p.id.equals(id))).go();

      // Returns true if at least one row was deleted
      return Success(rowsAffected > 0);
    } catch (e) {
      return Failure(
        'Error deleting product: ${e.toString()}',
        e as Exception?,
      );
    }
  }
}
