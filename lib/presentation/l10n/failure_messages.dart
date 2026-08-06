import '../../domain/failures/failure.dart';
import '../../l10n/generated/app_localizations.dart';

/// Turns a domain [Failure] into a sentence the user can read.
///
/// This is the other half of the contract in `ARCHITECTURE.md` §5: failures
/// carry a stable `code` and never any text, so that the domain stays free of
/// language and the translation lives where translations belong. This extension
/// is the single place where a code becomes words.
extension FailureMessages on AppLocalizations {
  /// The message for [failure].
  ///
  /// Switches on the code rather than the runtime type because
  /// `ValidationFailure` carries several codes and they need different
  /// sentences — "today is not one of your days" and "you already did your
  /// three this week" are both validation failures and nothing alike.
  ///
  /// An unrecognized code falls back to the generic message. That is a
  /// deliberate soft landing for the user; the hard landing is
  /// `translations_test.dart`, which fails the build if a code in
  /// [FailureCodes] has no sentence of its own here.
  String messageForFailure(Failure failure) =>
      messageForFailureCode(failure.code);

  /// [messageForFailure] for callers that only hold the code, such as a bloc
  /// state that stored it.
  String messageForFailureCode(String code) => switch (code) {
    FailureCodes.network => errorNetwork,
    FailureCodes.notFound => errorNotFound,
    FailureCodes.permission => errorPermission,
    FailureCodes.cache => errorCache,
    FailureCodes.unknown => errorUnknown,
    FailureCodes.completionArchived => errorCompletionArchived,
    FailureCodes.completionOutsideRange => errorCompletionOutsideRange,
    FailureCodes.completionFutureDate => errorCompletionFutureDate,
    FailureCodes.completionAlreadyRecorded => errorCompletionAlreadyRecorded,
    FailureCodes.completionNotScheduled => errorCompletionNotScheduled,
    FailureCodes.completionQuotaReached => errorCompletionQuotaReached,
    _ => errorUnknown,
  };
}
