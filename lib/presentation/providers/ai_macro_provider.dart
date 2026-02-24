import 'dart:async';

import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../core/services/openai_service.dart';
import '../../data/models/meal_entry_model.dart';

/// Provides the [OpenAiService] singleton, reading the API key from the .env
/// file loaded at startup via flutter_dotenv.
final openAiServiceProvider = Provider<OpenAiService>((ref) {
  final apiKey = dotenv.env['OPENAI_API_KEY'] ?? '';
  return OpenAiService(apiKey);
});

/// State: `AsyncValue<MealEntry?>`
///   - `AsyncData(null)` — idle (initial and after reset)
///   - `AsyncLoading()`  — API call in progress
///   - `AsyncData(entry)` — success; entry holds estimated nutrients
///   - `AsyncError(...)`  — call failed; message surfaced to the UI
class AiMacroNotifier extends AsyncNotifier<MealEntry?> {
  @override
  FutureOr<MealEntry?> build() => null; // idle

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
    AsyncNotifierProvider<AiMacroNotifier, MealEntry?>(AiMacroNotifier.new);

