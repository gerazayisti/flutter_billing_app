/// Abstract interface for cloud synchronisation.
/// Implemented by [SupabaseSyncService]; can be swapped for Firebase, etc.
abstract class CloudSyncService {
  bool get isConfigured;
  bool get isSignedIn;
  String? get userEmail;

  Future<void> initialize();

  Future<bool> signIn(String email, String password);
  Future<void> signOut();

  /// Push all local data to the cloud since [lastSync].
  /// Returns the timestamp of the push (store as next lastSync).
  Future<DateTime> pushAll({DateTime? lastSync});

  /// Pull all records for this shop from the cloud and merge into Hive.
  Future<void> pullAll();

  /// Quick push for a single order (called after every sale).
  Future<void> pushOrder(Map<String, dynamic> orderJson);

  /// Remove a single record from the cloud (used when deleting a product).
  Future<void> deleteRecord(String entityType, String id);
}
