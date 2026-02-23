import 'package:sqflite/sqflite.dart';

/// Abstract base for every versioned schema migration.
///
/// Each concrete subclass represents one schema version bump.
/// [toVersion] must be monotonically increasing starting at 1.
abstract class AppMigration {
  /// The schema version this migration produces.
  int get toVersion;

  /// Human-readable description of what this migration does.
  String get description;

  /// Apply the migration (upgrade path).
  Future<void> up(Database db);

  /// Revert the migration (downgrade path).
  Future<void> down(Database db);
}

