import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:mooze_mobile/features/merchant/domain/entities/product_entity.dart';
import 'package:mooze_mobile/features/merchant/presentation/providers/usecase_providers.dart';
import 'package:mooze_mobile/shared/utils/result.dart';

part 'product_controller.g.dart';

@riverpod
class ProductController extends _$ProductController {
  @override
  Future<List<ProductEntity>> build() async {
    return await _fetchProducts();
  }

  Future<List<ProductEntity>> _fetchProducts() async {
    final getAllProductsUseCase = ref.read(getAllProductsUseCaseProvider);
    final result = await getAllProductsUseCase();

    return result.fold((products) => products, (error) {
      return [];
    });
  }

  Future<void> addProduct(ProductEntity product) async {
    final createProductUseCase = ref.read(createProductUseCaseProvider);
    final result = await createProductUseCase(product);

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
    final updateProductUseCase = ref.read(updateProductUseCaseProvider);
    final result = await updateProductUseCase(product);

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
    final deleteProductUseCase = ref.read(deleteProductUseCaseProvider);
    final result = await deleteProductUseCase(id);

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
