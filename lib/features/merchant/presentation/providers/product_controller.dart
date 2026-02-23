import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:mooze_mobile/features/merchant/models/product.dart';
import 'package:mooze_mobile/features/merchant/presentation/providers/product_repository_provider.dart';
import 'package:mooze_mobile/shared/utils/result.dart';

part 'product_controller.g.dart';

@riverpod
class ProductController extends _$ProductController {
  @override
  Future<List<ProductEntity>> build() async {
    return await _fetchProducts();
  }

  Future<List<ProductEntity>> _fetchProducts() async {
    final repository = ref.read(productRepositoryProvider);
    final result = await repository.getAllProducts();

    return result.fold((products) => products, (error) {
      return [];
    });
  }

  Future<void> addProduct(ProductEntity product) async {
    final repository = ref.read(productRepositoryProvider);
    final result = await repository.createProduct(product);

    result.fold(
      (id) {
        ref.invalidateSelf();
      },
      (error) {
        throw Exception(error);
      },
    );
  }

  Future<void> updateProduct(ProductEntity product) async {
    final repository = ref.read(productRepositoryProvider);
    final result = await repository.updateProduct(product);

    result.fold(
      (success) {
        if (success) {
          ref.invalidateSelf();
        }
      },
      (error) {
        throw Exception(error);
      },
    );
  }

  Future<void> removeProduct(int id) async {
    final repository = ref.read(productRepositoryProvider);
    final result = await repository.deleteProduct(id);

    result.fold(
      (success) {
        if (success) {
          ref.invalidateSelf();
        }
      },
      (error) {
        throw Exception(error);
      },
    );
  }

  Future<void> fetchProducts() async {
    ref.invalidateSelf();
  }
}
