import 'package:riverpod_annotation/riverpod_annotation.dart';
import 'package:mooze_mobile/features/merchant/data/repositories/product_repository_impl.dart';
import 'package:mooze_mobile/features/merchant/domain/repositories/product_repository.dart';
import 'package:mooze_mobile/shared/infra/db/providers/app_database_provider.dart';

part 'product_repository_provider.g.dart';

@riverpod
ProductRepository productRepository(ProductRepositoryRef ref) {
  final database = ref.watch(appDatabaseProvider);
  return ProductRepositoryImpl(database);
}
