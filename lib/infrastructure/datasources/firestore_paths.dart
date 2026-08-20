/// Where documents live in Firestore.
///
/// Split out of the datasources so it can be asserted on. These strings have to
/// match `firestore.rules` exactly — the rules grant access to
/// `users/{uid}/**` and nothing else, so a path built one segment differently
/// is not a bug that shows up as wrong data, it is a `permission-denied` in
/// production and nowhere else.
abstract final class FirestorePaths {
  /// Root collection of user documents.
  static const String users = 'users';

  /// Subcollection holding a user's habits.
  static const String habits = 'habits';

  /// Subcollection holding a user's check-ins.
  ///
  /// Flat under the user rather than nested under each habit — see
  /// `ARCHITECTURE.md` §6.3 for why the query patterns demand it.
  static const String entries = 'entries';

  /// Full path of a user's habit collection.
  static String habitsOf(String uid) => '$users/$uid/$habits';

  /// Full path of a user's entry collection.
  static String entriesOf(String uid) => '$users/$uid/$entries';

  /// Full path of one habit document.
  static String habit(String uid, String habitId) =>
      '${habitsOf(uid)}/$habitId';

  /// Full path of one entry document, whose id encodes habit and day.
  static String entry(String uid, String entryId) =>
      '${entriesOf(uid)}/$entryId';
}
