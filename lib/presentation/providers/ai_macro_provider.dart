import 'dart:async';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/openai_service.dart';
import '../../data/repositories/ai_log_repository.dart';
import '../../data/repositories/sqlite_ai_log_repository.dart';
import 'database_provider.dart';

/// Provides the [AiLogRepository] backed by the open SQLite database.
final aiLogRepositoryProvider = Provider<AiLogRepository>((ref) {
  final dbAsync = ref.watch(databaseProvider);
  return dbAsync.when(
    data: (db) => SqliteAiLogRepository(db),
    loading: () => throw StateError('Database is not ready yet'),
    error: (e, _) => throw StateError('Database error: $e'),
  );
});

/// Provides the [OpenAiService] singleton, reading the API key from the .env
/// file loaded at startup via flutter_dotenv, and injecting [AiLogRepository]
/// for automatic persistence of every API call.
final openAiServiceProvider = Provider<OpenAiService>((ref) {
  final apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
  final aiLogRepo = ref.watch(aiLogRepositoryProvider);
  return OpenAiService(apiKey, aiLogRepo);
});

/// State: `AsyncValue<AiMacroResult?>`
///   - `AsyncData(null)`   — idle (initial and after reset)
///   - `AsyncLoading()`    — API call in progress
///   - `AsyncData(result)` — success; result holds entry + confidence + note
///   - `AsyncError(...)`   — call failed; message surfaced to the UI
class AiMacroNotifier extends AsyncNotifier<AiMacroResult?> {
  @override
  FutureOr<AiMacroResult?> build() => null; // idle

  /// Sends [description] to OpenAI and populates the state with the result.
  Future<void> estimate(String description) async {
    state = const AsyncLoading();
    state = await AsyncValue.guard(
      () => ref.read(openAiServiceProvider).estimateMacros(description),
    );
  }

  /// Resets back to idle after the UI has consumed the result or error.
  void reset() => state = const AsyncData(null);
}

final aiMacroProvider =
    AsyncNotifierProvider<AiMacroNotifier, AiMacroResult?>(AiMacroNotifier.new);

