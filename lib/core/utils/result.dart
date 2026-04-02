/// A result type for handling success and error cases
/// Similar to Either in functional programming
class Result<T> {
  final T? data;
  final AppError? error;
  final bool isSuccess;

  const Result._({
    this.data,
    this.error,
    required this.isSuccess,
  });

  /// Create a success result
  factory Result.success(T data) => Result._(data: data, isSuccess: true);

  /// Create an error result
  factory Result.failure(AppError error) => Result._(error: error, isSuccess: false);

  /// Check if result is success
  bool get isFailure => !isSuccess;

  /// Get data or throw if error
  T getOrThrow() {
    if (isSuccess && data != null) return data!;
    throw error ?? AppError.unknown('Unknown error');
  }

  /// Get data or return default
  T getOrElse(T defaultValue) => isSuccess && data != null ? data! : defaultValue;

  /// Fold operation - handle both cases
  R fold<R>(R Function(T) onSuccess, R Function(AppError) onFailure) {
    final data = this.data;
    if (isSuccess && data != null) return onSuccess(data);
    return onFailure(error ?? AppError.unknown('Unknown error'));
  }

  /// Map operation for success case
  Result<R> map<R>(R Function(T) transform) {
    final data = this.data;
    if (isSuccess && data != null) {
      return Result.success(transform(data));
    }
    return Result.failure(error ?? AppError.unknown('Unknown error'));
  }

  @override
  String toString() => isSuccess ? 'Success($data)' : 'Failure($error)';
}

/// Application error class
class AppError {
  final String message;
  final ErrorType type;
  final StackTrace? stackTrace;

  const AppError({
    required this.message,
    required this.type,
    this.stackTrace,
  });

  factory AppError.notFound(String message) => AppError(
        message: message,
        type: ErrorType.notFound,
      );

  factory AppError.validation(String message) => AppError(
        message: message,
        type: ErrorType.validation,
      );

  factory AppError.network(String message) => AppError(
        message: message,
        type: ErrorType.network,
      );

  factory AppError.database(String message) => AppError(
        message: message,
        type: ErrorType.database,
      );

  factory AppError.unknown(String message) => AppError(
        message: message,
        type: ErrorType.unknown,
      );

  @override
  String toString() => 'AppError($type): $message';
}

enum ErrorType {
  notFound,
  validation,
  network,
  database,
  unknown,
}
