import 'package:equatable/equatable.dart';

/// Represents a single OpenAI API call, stored in the `ai_logs` table.
///
/// [success] is stored as INTEGER (1/0) in SQLite; [errorMessage] is NULL
/// when the call succeeded.
class AiLog extends Equatable {
  final int? id;
  final DateTime timestamp;
  final String request;
  final String response;
  final bool success;
  final String? errorMessage;

  const AiLog({
    this.id,
    required this.timestamp,
    required this.request,
    required this.response,
    required this.success,
    this.errorMessage,
  });

  // ── Serialisation ──────────────────────────────────────────────────────

  factory AiLog.fromMap(Map<String, dynamic> m) => AiLog(
        id: m['id'] as int?,
        timestamp: DateTime.parse(m['timestamp'] as String),
        request: m['request'] as String,
        response: m['response'] as String,
        success: (m['success'] as int) == 1,
        errorMessage: m['error_message'] as String?,
      );

  Map<String, dynamic> toMap() => {
        if (id != null) 'id': id,
        'timestamp': timestamp.toIso8601String(),
        'request': request,
        'response': response,
        'success': success ? 1 : 0,
        'error_message': errorMessage,
      };

  // ── copyWith ───────────────────────────────────────────────────────────

  AiLog copyWith({
    int? id,
    DateTime? timestamp,
    String? request,
    String? response,
    bool? success,
    String? errorMessage,
  }) =>
      AiLog(
        id: id ?? this.id,
        timestamp: timestamp ?? this.timestamp,
        request: request ?? this.request,
        response: response ?? this.response,
        success: success ?? this.success,
        errorMessage: errorMessage ?? this.errorMessage,
      );

  // ── Equatable ──────────────────────────────────────────────────────────

  @override
  List<Object?> get props =>
      [id, timestamp, request, response, success, errorMessage];
}

