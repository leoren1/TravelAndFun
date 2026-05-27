sealed class Result<T, E> {
  const Result();
}

final class Success<T, E> extends Result<T, E> {
  final T value;
  const Success(this.value);
}

final class Failure<T, E> extends Result<T, E> {
  final E error;
  const Failure(this.error);
}

extension ResultExtensions<T, E> on Result<T, E> {
  bool get isSuccess => this is Success<T, E>;
  bool get isFailure => this is Failure<T, E>;

  T get valueOrThrow {
    if (this is Success<T, E>) return (this as Success<T, E>).value;
    throw StateError('Result is a Failure: ${(this as Failure<T, E>).error}');
  }

  E get errorOrThrow {
    if (this is Failure<T, E>) return (this as Failure<T, E>).error;
    throw StateError('Result is a Success');
  }

  R fold<R>({required R Function(T) onSuccess, required R Function(E) onFailure}) {
    return switch (this) {
      Success(:final value) => onSuccess(value),
      Failure(:final error) => onFailure(error),
    };
  }
}
