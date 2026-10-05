import '../entities/chain.dart';

/// Sealed root of all domain-level failures. No exceptions cross layer
/// boundaries — every async API returns `Either<Failure, T>`.
sealed class Failure {
  const Failure(this.message, {this.cause, this.stackTrace});
  final String message;
  final Object? cause;
  final StackTrace? stackTrace;

  @override
  String toString() => '$runtimeType($message)';
}

class BootFailure extends Failure {
  const BootFailure(super.message,
      {required this.phase, super.cause, super.stackTrace});
  final String phase;
}

class SyncFailure extends Failure {
  const SyncFailure(super.message,
      {required this.chain, super.cause, super.stackTrace});
  final ChainId chain;
}

class ServiceFailure extends Failure {
  const ServiceFailure(super.message,
      {required this.chain, super.cause, super.stackTrace});
  final ChainId chain;
}

class StorageFailure extends Failure {
  const StorageFailure(super.message, {super.cause, super.stackTrace});
}

class CredentialFailure extends Failure {
  const CredentialFailure(super.message, {super.cause, super.stackTrace});
}

class SessionFailure extends Failure {
  const SessionFailure(super.message, {super.cause, super.stackTrace});
}

class PlatformFailure extends Failure {
  const PlatformFailure(super.message, {super.cause, super.stackTrace});
}

/// Generic catch-all for unexpected errors. Prefer the typed variants above.
class UnexpectedFailure extends Failure {
  const UnexpectedFailure(super.message, {super.cause, super.stackTrace});
}
