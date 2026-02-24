import 'package:sqflite/sqflite.dart';

import '../models/ai_log_model.dart';
import 'ai_log_repository.dart';

class SqliteAiLogRepository implements AiLogRepository {
  SqliteAiLogRepository(this._db);

  final Database _db;
  static const _table = 'ai_logs';

  // ── insert ─────────────────────────────────────────────────────────────

  @override
  Future<AiLog> insert(AiLog log) async {
    final map = log.toMap()..remove('id');
    final id = await _db.insert(_table, map);
    return log.copyWith(id: id);
  }

  // ── getAll ─────────────────────────────────────────────────────────────

  @override
  Future<List<AiLog>> getAll() async {
    final rows = await _db.query(_table, orderBy: 'id DESC');
    return rows.map(AiLog.fromMap).toList();
  }

  // ── getRecent ──────────────────────────────────────────────────────────

  @override
  Future<List<AiLog>> getRecent(int limit) async {
    final rows = await _db.query(_table, orderBy: 'id DESC', limit: limit);
    return rows.map(AiLog.fromMap).toList();
  }
}

