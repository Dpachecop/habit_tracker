import 'package:equatable/equatable.dart';

/// Something that went wrong, as a value rather than an exception.
///
/// Repositories return `Either<Failure, T>`, which puts the error in the
/// signature where the caller cannot forget about it. Infrastructure catches
/// the concrete exception and translates it here; presentation turns the [code]
/// into a sentence.
///
/// **A failure carries no user-facing text.** Only a stable [code]. The domain
/// has no business knowing the app's language, and hard-coding Spanish strings
/// down here would make adding i18n a rewrite of every layer
/// (`ARCHITECTURE.md` §5).
sealed class Failure extends Equatable {
  /// [code] is a stable key, safe to switch on and to use as a translation key.
  const Failure({required this.code, this.cause});

  /// Stable identifier for what went wrong. Never shown as-is.
  final String code;

  /// The original exception, kept for logging. Deliberately outside [props] —
  /// two network failures are the same failure even if the sockets differed.
  final Object? cause;

  @override
  List<Object?> get props => <Object?>[code];

  @override
  String toString() => '$runtimeType($code)';
}

/// No connectivity, a timeout, or a server that did not answer.
///
/// Rare in practice here: Firestore's offline cache absorbs most of it and
/// replays the write later.
final class NetworkFailure extends Failure {
  /// Builds a network failure, optionally carrying the exception that caused it.
  const NetworkFailure({super.cause}) : super(code: FailureCodes.network);
}

/// The requested habit or entry is not there.
final class NotFoundFailure extends Failure {
  /// Builds a not-found failure, optionally carrying the underlying exception.
  const NotFoundFailure({super.cause}) : super(code: FailureCodes.notFound);
}

/// The security rules rejected the operation, or there is no signed-in user.
final class PermissionFailure extends Failure {
  /// Builds a permission failure, optionally carrying the underlying exception.
  const PermissionFailure({super.cause}) : super(code: FailureCodes.permission);
}

/// A domain rule said no — most often the no-over-completion rule of §3.5.
///
/// The only failure whose code varies, because the UI has to explain *which*
/// rule blocked the action: "today is not a scheduled day" and "you already did
/// your 3 this week" are different sentences.
final class ValidationFailure extends Failure {
  /// [code] should come from [FailureCodes] so presentation can switch on it
  /// exhaustively.
  const ValidationFailure({required super.code, super.cause});
}

/// The local cache could not be read or written.
final class CacheFailure extends Failure {
  /// Builds a cache failure, optionally carrying the underlying exception.
  const CacheFailure({super.cause}) : super(code: FailureCodes.cache);
}

/// Anything that was not anticipated. Always log the [Failure.cause].
final class UnknownFailure extends Failure {
  /// Builds an unknown failure, optionally carrying the underlying exception.
  const UnknownFailure({super.cause}) : super(code: FailureCodes.unknown);
}

/// Every failure code in one place.
///
/// Presentation maps these to text, so a code that exists here and nowhere in
/// the string table is a visible bug rather than a silent one. Keeping them as
/// constants instead of raw literals is what makes that check possible.
abstract final class FailureCodes {
  /// [NetworkFailure].
  static const String network = 'network';

  /// [NotFoundFailure].
  static const String notFound = 'not_found';

  /// [PermissionFailure].
  static const String permission = 'permission';

  /// [CacheFailure].
  static const String cache = 'cache';

  /// [UnknownFailure].
  static const String unknown = 'unknown';

  /// Tried to check a habit that has been archived.
  static const String completionArchived = 'completion.archived';

  /// Tried to check a day outside the habit's date range.
  static const String completionOutsideRange = 'completion.outside_range';

  /// Tried to check a day that has not happened yet.
  static const String completionFutureDate = 'completion.future_date';

  /// Tried to check a day that is already checked.
  static const String completionAlreadyRecorded = 'completion.already_recorded';

  /// Tried to check a day the habit is not scheduled on (mode A, §3.5).
  static const String completionNotScheduled = 'completion.not_scheduled';

  /// The period's quota is already full (mode B, §3.5).
  static const String completionQuotaReached = 'completion.quota_reached';
}
