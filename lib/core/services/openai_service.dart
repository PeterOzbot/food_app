import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../data/models/ai_log_model.dart';
import '../../data/models/meal_entry_model.dart';
import '../../data/repositories/ai_log_repository.dart';

/// Thrown when the OpenAI API call fails for any reason.
class OpenAiException implements Exception {
  const OpenAiException(this.message);
  final String message;

  @override
  String toString() => 'OpenAiException: $message';
}

/// Bundles the AI-estimated [MealEntry] with the confidence level and any
/// assumptions the model made during nutritional estimation.
class AiMacroResult {
  const AiMacroResult({
    required this.entry,
    required this.confidence,
    this.note,
  });

  /// Nutritional stub returned by the AI (date and text are placeholders).
  final MealEntry entry;

  /// AI self-assessment: `'high'`, `'medium'`, or `'low'`.
  final String confidence;

  /// Optional explanation of assumptions (e.g. estimated portion sizes).
  final String? note;
}

class OpenAiService {
  static const _endpoint = 'https://api.openai.com/v1/chat/completions';
  static const _model = 'gpt-4o-mini';

  static const _systemPrompt = '''
You are a precise nutritionist and expert in food nutritional values. Your task is to analyze the meal description and calculate the total nutritional values.

Follow these steps exactly:

1. Break down the description into individual ingredients and their quantities in grams. If a quantity is not specified, use a realistic average portion (and note this in the "note" field).

2. For each ingredient, look up the standard nutritional values per 100 g (use reliable average values from USDA, EU data, or generally accepted databases).

3. Calculate the scaled values for the actual quantity in grams.

4. Sum everything up for the entire meal.

5. Return ONLY a valid JSON object, with no additional text, no introduction, no explanation outside the JSON. The JSON must follow this exact structure:

{
  "meal_description": "original description for reference",
  "note": "any assumptions made",
  "confidence": "high / medium / low",

  "calories": number,
  "protein": number,
  "totalFat": number,
  "carbohydrates": number,
  "dietaryFiber": number,
  "sugars": number,

  "saturatedFat": number | null,
  "transFat": number | null,

  "vitaminA": number | null,
  "vitaminC": number | null,
  "vitaminD": number | null,
  "vitaminE": number | null,
  "vitaminK": number | null,
  "thiaminB1": number | null,
  "riboflavinB2": number | null,
  "niacinB3": number | null,
  "vitaminB6": number | null,
  "folateB9": number | null,
  "vitaminB12": number | null,
  "pantothenicAcidB5": number | null,
  "biotinB7": number | null,

  "calcium": number | null,
  "iron": number | null,
  "magnesium": number | null,
  "phosphorus": number | null,
  "potassium": number | null,
  "sodium": number | null,
  "zinc": number | null,
  "copper": number | null,
  "manganese": number | null,
  "selenium": number | null,

  "cholesterol": number | null,
  "water": number | null
}

Be very accurate with the numbers (round to 1 decimal place where appropriate). If any value is unknown, use 0 and add a note.
Start immediately with the JSON object.''';

  OpenAiService(this._apiKey, this._aiLogRepository);

  final String _apiKey;
  final AiLogRepository _aiLogRepository;

  /// Returns an [AiMacroResult] with the AI-estimated nutritional entry plus
  /// confidence level and notes.
  ///
  /// The entry's [date] and [text] are placeholders — the caller must merge
  /// those from the current form state using [MealEntry.copyWith].
  ///
  /// Throws [OpenAiException] on network error, non-200 status, or bad JSON.
  Future<AiMacroResult> estimateMacros(String description) async {
    final timestamp = DateTime.now();

    // ── Network call ───────────────────────────────────────────────────────
    final http.Response response;
    try {
      response = await http.post(
        Uri.parse(_endpoint),
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $_apiKey',
        },
        body: jsonEncode({
          'model': _model,
          'temperature': 0.2,
          'max_tokens': 1500,
          'response_format': {'type': 'json_object'},
          'messages': [
            {'role': 'system', 'content': _systemPrompt},
            {'role': 'user', 'content': 'Meal description: """$description"""'},
          ],
        }),
      );
    } catch (e) {
      await _logFailure(timestamp, description, 'Network error: $e');
      throw OpenAiException('Network error: $e');
    }

    // ── HTTP-level errors ──────────────────────────────────────────────────
    if (response.statusCode == 429) {
      const msg = 'Rate limit exceeded — retry later.';
      await _logFailure(timestamp, description, msg);
      throw const OpenAiException(msg);
    }
    if (response.statusCode != 200) {
      final msg = 'HTTP ${response.statusCode}: ${response.body}';
      await _logFailure(timestamp, description, msg);
      throw OpenAiException(msg);
    }

    // ── Parse outer envelope ───────────────────────────────────────────────
    final Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      const msg = 'Could not decode API response as JSON.';
      await _logFailure(timestamp, description, msg);
      throw const OpenAiException(msg);
    }

    final content =
        (body['choices'] as List?)?.first['message']['content'] as String?;
    if (content == null || content.isEmpty) {
      const msg = 'Empty content in API response.';
      await _logFailure(timestamp, description, msg);
      throw const OpenAiException(msg);
    }

    // ── Parse inner AI JSON ────────────────────────────────────────────────
    final Map<String, dynamic> aiJson;
    try {
      aiJson = jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      const msg = 'AI response was not valid JSON.';
      await _logFailure(timestamp, description, msg, rawResponse: content);
      throw const OpenAiException(msg);
    }

    debugPrint(
      '[AI] confidence=${aiJson['confidence']}, note=${aiJson['note']}',
    );

    // ── Persist success log ────────────────────────────────────────────────
    await _persistLog(
      AiLog(
        timestamp: timestamp,
        request: description,
        response: content,
        success: true,
      ),
    );

    final confidence =
        ((aiJson['confidence'] as String?) ?? 'low').toLowerCase();
    final noteRaw = aiJson['note'] as String?;
    final note = (noteRaw != null && noteRaw.isNotEmpty) ? noteRaw : null;

    return AiMacroResult(
      entry: MealEntry.fromAiJson(aiJson),
      confidence: confidence,
      note: note,
    );
  }

  // ── Helpers ────────────────────────────────────────────────────────────

  Future<void> _logFailure(
    DateTime timestamp,
    String request,
    String errorMessage, {
    String rawResponse = '',
  }) =>
      _persistLog(
        AiLog(
          timestamp: timestamp,
          request: request,
          response: rawResponse,
          success: false,
          errorMessage: errorMessage,
        ),
      );

  /// Writes [log] to the database, silently swallowing errors so a DB
  /// failure never breaks the AI-fill user flow.
  Future<void> _persistLog(AiLog log) async {
    try {
      await _aiLogRepository.insert(log);
    } catch (e) {
      debugPrint('[AI] Failed to persist AiLog: $e');
    }
  }
}

