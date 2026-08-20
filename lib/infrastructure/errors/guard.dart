import 'dart:async';

import 'package:fpdart/fpdart.dart';

import '../../domain/failures/failure.dart';
import 'failure_mapper.dart';

/// Wraps throwing datasource calls into the `Either` the repositories promise.
///
/// The layer split is "datasources throw, repositories translate"; without
/// this, every repository method would carry the same six lines of try/catch
/// and one of them would eventually be written wrong.
abstract final class Guard {
  /// Runs [operation], returning its value as a `Right` or the mapped failure
  /// as a `Left`.
  static Future<Either<Failure, T>> future<T>(
    Future<T> Function() operation,
  ) async {
    try {
      return Right<Failure, T>(await operation());
    } catch (error, stackTrace) {
      return Left<Failure, T>(FailureMapper.from(error, stackTrace));
    }
  }

  /// [future] for an operation that decides its own failures.
  ///
  /// Used where a domain rule can refuse — "no habit with that id", "the quota
  /// is full" — and the repository has to return that verdict rather than an
  /// exception it just caught.
  static Future<Either<Failure, T>> futureEither<T>(
    Future<Either<Failure, T>> Function() operation,
  ) async {
    try {
      return await operation();
    } catch (error, stackTrace) {
      return Left<Failure, T>(FailureMapper.from(error, stackTrace));
    }
  }

  /// Wraps a stream so its errors arrive as `Left` events.
  ///
  /// Deliberately not `handleError`, which would let the error terminate the
  /// subscription: the home screen listens to `watchHabits` for the life of the
  /// app, and one transient failure must not leave it permanently silent. The
  /// transformer swallows the error, emits it as a value, and keeps going.
  static Stream<Either<Failure, T>> stream<T>(Stream<T> source) {
    return source.transform(
      StreamTransformer<T, Either<Failure, T>>.fromHandlers(
        handleData:
            (T data, EventSink<Either<Failure, T>> sink) =>
                sink.add(Right<Failure, T>(data)),
        handleError:
            (
              Object error,
              StackTrace stackTrace,
              EventSink<Either<Failure, T>> sink,
            ) => sink.add(
              Left<Failure, T>(FailureMapper.from(error, stackTrace)),
            ),
      ),
    );
  }
}
