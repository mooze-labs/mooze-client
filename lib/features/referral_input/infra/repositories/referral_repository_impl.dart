import 'package:mooze_mobile/features/referral_input/domain/repositories/referral_repository.dart';
import 'package:mooze_mobile/features/referral_input/infra/datasources/referral_datasource.dart';
import 'package:mooze_mobile/shared/utils/result.dart';

/// Referral Repository Implementation (Infrastructure Layer)
///
/// Bridges the domain layer and external data sources.
/// Delegates data access to the data source and handles
/// unexpected exceptions by converting them to Failure results.
class ReferralRepositoryImpl implements ReferralRepository {
  final ReferralDataSource _dataSource;

  const ReferralRepositoryImpl(this._dataSource);

  @override
  Future<Result<String?>> getExistingReferral() async {
    try {
      return await _dataSource.getExistingReferral();
    } catch (e) {
      return Failure(
        'Erro ao buscar código de indicação: ${e.toString()}',
        e as Exception?,
      );
    }
  }

  @override
  Future<Result<bool>> validateReferralCode(String code) async {
    try {
      return await _dataSource.validateReferralCode(code);
    } catch (e) {
      return Failure(
        'Erro ao validar código: ${e.toString()}',
        e as Exception?,
      );
    }
  }

  @override
  Future<Result<void>> applyReferralCode(String code) async {
    try {
      return await _dataSource.applyReferralCode(code);
    } catch (e) {
      return Failure(
        'Erro ao aplicar código: ${e.toString()}',
        e as Exception?,
      );
    }
  }
}
