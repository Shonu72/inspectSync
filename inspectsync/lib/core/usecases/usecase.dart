import 'package:dartz/dartz.dart';
import '../error/failure.dart';

abstract class UseCase<T, Params> {
  Future<Either<Failure, T>> call(Params params);
}

class NoParams {
  const NoParams();
}
