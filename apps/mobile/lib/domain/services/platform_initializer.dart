import 'package:fpdart/fpdart.dart';

import '../failures/failure.dart';

/// Idempotent platform-level setup (FFI inits, prefs, etc.).
/// Boot calls this exactly once on first launch.
abstract interface class PlatformInitializer {
  Future<Either<PlatformFailure, Unit>> run();
}
