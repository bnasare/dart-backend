abstract class UseCase<Result, Params> {
  Future<Result> call(Params params);
}

class NoParams {
  const NoParams();
}

class ObjectParams<T> {
  const ObjectParams(this.value);

  final T value;
}
