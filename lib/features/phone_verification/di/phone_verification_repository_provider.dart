import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/datasources.dart';
import '../data/repositories.dart';

import '../domain/repositories/phone_verification_repository.dart';

final phoneVerificationRepositoryProvider =
    Provider<PhoneVerificationRepository>((ref) {
      final useMock = bool.fromEnvironment('MOCK_REQUESTS');
      return useMock
          ? MockPhoneVerificationRepositoryImpl()
          : PhoneVerificationRepositoryImpl(
            phoneVerificationDatasource: PhoneVerificationDatasource(),
            deviceInfoDatasource: DeviceInfoDatasource(),
            ipAddressDatasource: IpAddressDatasource(),
            verificationStatusDatasource: VerificationStatusDatasource(),
          );
    });
