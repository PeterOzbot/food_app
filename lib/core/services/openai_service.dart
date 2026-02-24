import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;

import '../../data/models/meal_entry_model.dart';

/// Thrown when the OpenAI API call fails for any reason.
class OpenAiException implements Exception {
  const OpenAiException(this.message);
  final String message;

  @override
  String toString() => 'OpenAiException: $message';
}

class OpenAiService {
  static const _endpoint = 'https://api.openai.com/v1/chat/completions';
  static const _model = 'gpt-4o-mini';

  static const _systemPrompt = '''
You are a precise nutritionist. Given a meal description, estimate the nutritional content and return ONLY a valid JSON object with the keys listed below. Use null (not 0) for values you cannot confidently estimate. Round all numbers to 1 decimal place.

Required keys (camelCase, matching Dart field names):
calories, protein, totalFat, carbohydrates, dietaryFiber, sugars,
saturatedFat, transFat, cholesterol, water,
vitaminA, vitaminC, vitaminD, vitaminE, vitaminK,
thiaminB1, riboflavinB2, niacinB3, vitaminB6, folateB9,
vitaminB12, pantothenicAcidB5, biotinB7,
calcium, iron, magnesium, phosphorus, potassium,
sodium, zinc, copper, manganese, selenium,
confidenceLevel, notes

Steps: break down ingredients, calculate per-100g values, scale to actual quantities, sum totals.
confidenceLevel must be one of: "high", "medium", "low".
notes should briefly explain any assumptions made.''';

  OpenAiService(this._apiKey);

  final String _apiKey;

  /// Returns a [MealEntry] stub with nutritional fields filled by the AI.
  ///
  /// The stub has placeholder [date] and empty [text] — the caller must
  /// merge those from the current form state using [MealEntry.copyWith].
  ///
  /// Throws [OpenAiException] on network error, non-200 status, or bad JSON.
  Future<MealEntry> estimateMacros(String description) async {
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
          'max_tokens': 800,
          'response_format': {'type': 'json_object'},
          'messages': [
            {'role': 'system', 'content': _systemPrompt},
            {'role': 'user', 'content': 'Meal description: $description'},
          ],
        }),
      );
    } catch (e) {
      throw OpenAiException('Network error: $e');
    }

    if (response.statusCode == 429) {
      throw const OpenAiException('Rate limit exceeded — retry later.');
    }
    if (response.statusCode != 200) {
      throw OpenAiException('HTTP ${response.statusCode}: ${response.body}');
    }

    final Map<String, dynamic> body;
    try {
      body = jsonDecode(response.body) as Map<String, dynamic>;
    } catch (_) {
      throw const OpenAiException('Could not decode API response as JSON.');
    }

    final content =
        (body['choices'] as List?)?.first['message']['content'] as String?;
    if (content == null || content.isEmpty) {
      throw const OpenAiException('Empty content in API response.');
    }

    final Map<String, dynamic> json;
    try {
      json = jsonDecode(content) as Map<String, dynamic>;
    } catch (_) {
      throw const OpenAiException('AI response was not valid JSON.');
    }

    debugPrint(
      '[AI] confidence=${json['confidenceLevel']}, notes=${json['notes']}',
    );

    return MealEntry.fromAiJson(json);
  }
}

