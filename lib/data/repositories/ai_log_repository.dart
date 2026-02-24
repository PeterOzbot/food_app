import '../models/ai_log_model.dart';

/// Abstract interface for all AI-log persistence operations.
/// The presentation layer depends only on this contract, never on SQLite directly.
abstract class AiLogRepository {
  /// Persists a new log entry and returns the saved copy with its assigned [id].
  Future<AiLog> insert(AiLog log);

  /// Returns all log entries, most-recent first.
  Future<List<AiLog>> getAll();

  /// Returns the most recent [limit] log entries, most-recent first.
  Future<List<AiLog>> getRecent(int limit);
}

