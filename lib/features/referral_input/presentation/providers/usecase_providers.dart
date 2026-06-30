import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mooze_mobile/features/referral_input/domain/repositories/referral_repository.dart';
import 'package:mooze_mobile/features/referral_input/domain/usecases/apply_referral_code_usecase.dart';
import 'package:mooze_mobile/features/referral_input/domain/usecases/get_existing_referral_usecase.dart';
import 'package:mooze_mobile/features/referral_input/external/datasources/referral_remote_datasource.dart';
import 'package:mooze_mobile/features/referral_input/infra/datasources/referral_datasource.dart';
import 'package:mooze_mobile/features/referral_input/infra/repositories/referral_repository_impl.dart';
import 'package:mooze_mobile/shared/user/providers/user_service_provider.dart';

/// Referral Input Dependency Injection Container
/// Clean Architecture: External → Infra → Domain → Presentation

// Data Sources
final referralDataSourceProvider = Provider<ReferralDataSource>((ref) {
  final userService = ref.watch(userServiceProvider);
  return ReferralRemoteDataSource(userService);
});

// Repositories
final referralRepositoryProvider = Provider<ReferralRepository>((ref) {
  final dataSource = ref.watch(referralDataSourceProvider);
  return ReferralRepositoryImpl(dataSource);
});

// Use Cases
final getExistingReferralUseCaseProvider =
    Provider<GetExistingReferralUseCase>((ref) {
      final repository = ref.watch(referralRepositoryProvider);
      return GetExistingReferralUseCase(repository);
    });

final applyReferralCodeUseCaseProvider =
    Provider<ApplyReferralCodeUseCase>((ref) {
      final repository = ref.watch(referralRepositoryProvider);
      return ApplyReferralCodeUseCase(repository);
    });
