import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/merchant/domain/repositories/merchant_mode_repository.dart';
import 'package:mooze_mobile/features/merchant/domain/repositories/product_repository.dart';
import 'package:mooze_mobile/features/merchant/domain/usecases/activate_merchant_mode_usecase.dart';
import 'package:mooze_mobile/features/merchant/domain/usecases/check_merchant_mode_usecase.dart';
import 'package:mooze_mobile/features/merchant/domain/usecases/create_product_usecase.dart';
import 'package:mooze_mobile/features/merchant/domain/usecases/deactivate_merchant_mode_usecase.dart';
import 'package:mooze_mobile/features/merchant/domain/usecases/delete_product_usecase.dart';
import 'package:mooze_mobile/features/merchant/domain/usecases/get_all_products_usecase.dart';
import 'package:mooze_mobile/features/merchant/domain/usecases/get_merchant_mode_origin_usecase.dart';
import 'package:mooze_mobile/features/merchant/domain/usecases/update_product_usecase.dart';
import 'package:mooze_mobile/features/merchant/external/datasources/merchant_mode_local_datasource.dart';
import 'package:mooze_mobile/features/merchant/external/datasources/product_drift_datasource.dart';
import 'package:mooze_mobile/features/merchant/infra/datasources/merchant_mode_datasource.dart';
import 'package:mooze_mobile/features/merchant/infra/datasources/product_datasource.dart';
import 'package:mooze_mobile/features/merchant/infra/repositories/merchant_mode_repository_impl.dart';
import 'package:mooze_mobile/features/merchant/infra/repositories/product_repository_impl.dart';
import 'package:mooze_mobile/shared/infra/db/providers/app_database_provider.dart';

/// Merchant Mode Dependency Injection Container
/// Clean Architecture: External → Infra → Domain → Presentation

// Data Sources
final productDataSourceProvider = Provider<ProductDataSource>((ref) {
  final database = ref.watch(appDatabaseProvider);
  return ProductDriftDataSource(database);
});

final merchantModeDataSourceProvider = Provider<MerchantModeDataSource>((ref) {
  return MerchantModeLocalDataSource();
});

// Repositories
final productRepositoryProvider = Provider<ProductRepository>((ref) {
  final dataSource = ref.watch(productDataSourceProvider);
  return ProductRepositoryImpl(dataSource);
});

final merchantModeRepositoryProvider = Provider<MerchantModeRepository>((ref) {
  final dataSource = ref.watch(merchantModeDataSourceProvider);
  return MerchantModeRepositoryImpl(dataSource);
});

// Product Use Cases
final createProductUseCaseProvider = Provider<CreateProductUseCase>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  return CreateProductUseCase(repository);
});

final getAllProductsUseCaseProvider = Provider<GetAllProductsUseCase>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  return GetAllProductsUseCase(repository);
});

final updateProductUseCaseProvider = Provider<UpdateProductUseCase>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  return UpdateProductUseCase(repository);
});

final deleteProductUseCaseProvider = Provider<DeleteProductUseCase>((ref) {
  final repository = ref.watch(productRepositoryProvider);
  return DeleteProductUseCase(repository);
});

// Merchant Mode Use Cases
final activateMerchantModeUseCaseProvider =
    Provider<ActivateMerchantModeUseCase>((ref) {
      final repository = ref.watch(merchantModeRepositoryProvider);
      return ActivateMerchantModeUseCase(repository);
    });

final deactivateMerchantModeUseCaseProvider =
    Provider<DeactivateMerchantModeUseCase>((ref) {
      final repository = ref.watch(merchantModeRepositoryProvider);
      return DeactivateMerchantModeUseCase(repository);
    });

final checkMerchantModeUseCaseProvider = Provider<CheckMerchantModeUseCase>((
  ref,
) {
  final repository = ref.watch(merchantModeRepositoryProvider);
  return CheckMerchantModeUseCase(repository);
});

final getMerchantModeOriginUseCaseProvider =
    Provider<GetMerchantModeOriginUseCase>((ref) {
      final repository = ref.watch(merchantModeRepositoryProvider);
      return GetMerchantModeOriginUseCase(repository);
    });
