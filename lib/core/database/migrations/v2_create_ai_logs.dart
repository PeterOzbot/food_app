import 'package:sqflite/sqflite.dart';

import 'app_migration.dart';

/// Version 2 — creates the ai_logs table for tracking OpenAI API interactions.
class V2CreateAiLogs extends AppMigration {
  @override
  int get toVersion => 2;

  @override
  String get description => 'Create ai_logs table';

  @override
  Future<void> up(Database db) async {
    await db.execute('''
      CREATE TABLE ai_logs (
        id            INTEGER PRIMARY KEY AUTOINCREMENT,
        timestamp     TEXT    NOT NULL,
        request       TEXT    NOT NULL,
        response      TEXT    NOT NULL,
        success       INTEGER NOT NULL,
        error_message TEXT
      )
    ''');
  }

  @override
  Future<void> down(Database db) async {
    await db.execute('DROP TABLE IF EXISTS ai_logs');
  }
}

