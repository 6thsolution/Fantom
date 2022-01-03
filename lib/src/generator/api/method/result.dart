import 'package:dio/dio.dart';

typedef ResultBuilder<T> = T Function(Response value);
typedef Mapper = FantomError? Function(Exception e, dynamic stacktrace);

/// [Result] contains result of a Future whether it throw an exception or awaited successfully
/// use extension function Future.toResult() to create convert a Future<T> into  a Future<Result<T,E>>
class Result<T, E extends FantomError> {
  final T? _data;
  final E? _error;

  Result._(this._data, this._error);

  factory Result.error(E e) => Result._(null, e);

  factory Result.success(T value) => Result._(value, null);

  /// use this method to consume the [Result] values
  Future fold({
    required Future Function(T value) onSuccess,
    required Future Function(E error) onError,
  }) async {
    if (_data != null) {
      await onSuccess(_data!);
    } else if (_error != null) {
      await onError(_error!);
    }
  }

  bool get isFailure => _error != null;

  bool get isSuccessful => _error == null;

  T get data {
    if (isFailure) {
      throw Exception('you cannot call getter data when Result has an error '
          'please use isSuccessful to check if Result is successful and has a data ');
    }
    return _data!;
  }

  E get error {
    if (isSuccessful) {
      throw Exception('you cannot call getter error when Result isSuccessful'
          'please use isFailure to check if Result has failed and has an error ');
    }
    return _error!;
  }

  @override
  String toString() {
    return 'Result{data: $_data, error: $_error}';
  }
}

extension FutureResultExt on Future<Response> {
  /// awaits the [Future] in a try/catch and returns an instance [Result]
  /// which contains the result value of Future if awaited successfully or the exception if Future throw
  /// an exception while being awaited
  Future<Result<T, FantomError>> toResult<T>(
    ResultBuilder<T> builder, [
    bool parserResponseErrors = true,
  ]) async {
    try {
      final response = await this;
      return Result.success(builder(response));
    } on DioError catch (e, stacktrace) {
      final exception = FantomExceptionMapping._mapping?.call(e, stacktrace) ??
          FantomError(
            exception: e,
            response: e.response,
            statusCode: e.response?.statusCode,
            stacktrace: stacktrace,
          );
      return Result.error(exception);
    } on Exception catch (e, stacktrace) {
      final exception = FantomExceptionMapping._mapping?.call(e, stacktrace) ??
          FantomError(exception: e, stacktrace: stacktrace);
      return Result.error(exception);
    }
  }
}

class FantomError implements Exception {
  final Exception exception;
  final Response? response;
  final int? statusCode;
  final dynamic stacktrace;

  FantomError({
    required this.exception,
    this.response,
    this.statusCode,
    this.stacktrace,
  });
}

class FantomExceptionMapping {
  FantomExceptionMapping._();

  static Mapper? _mapping;

  static bool get hasMapper => _mapping != null;

  static setMapper(Mapper mapper) {
    _mapping = mapper;
  }
}
