import 'package:fpdart/fpdart.dart';

import '../failures/failure.dart';

/// Domain-level result type. `Right(T)` = success, `Left(F)` = failure.
typedef Result<T, F extends Failure> = Either<F, T>;

/// Sugar for the most common shape: success carries [T], failure is [Failure].
typedef AnyResult<T> = Either<Failure, T>;
