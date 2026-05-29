import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import 'package:shared_preferences/shared_preferences.dart';

/// ──────────────────────────────────────────────
/// GeminiService — Interfaces with the Gemini 1.5
/// Flash multimodal API to identify plant species
/// and provide Explainable AI (XAI) justification.
/// ──────────────────────────────────────────────
class GeminiService {
  GenerativeModel? _model;

  /// The system prompt that constrains the AI to act as a botanical expert
  /// focused on Nigerian edible flora with safety-first reasoning.
  static const String _systemInstruction = '''
You are an expert botanist and ethnobotanist specializing in West African and Nigerian flora. 
Your task is to identify the plant in the provided image and return a detailed, structured analysis.

CRITICAL SAFETY RULES:
- If you are NOT confident in the identification (below 70%), say so explicitly.
- If the plant has a toxic look-alike, you MUST mention it and explain the visual differences.
- Never guarantee a plant is safe for consumption — always include a safety disclaimer.
- If you cannot identify the plant, say "Unknown species" with confidence 0.

RESPONSE FORMAT — You MUST respond with ONLY valid JSON matching this exact structure:
{
  "scientific_name": "The full binomial name (e.g. Vernonia amygdalina)",
  "common_name": "The most widely used English common name",
  "family": "The botanical family name",
  "confidence": 0.85,
  "reasoning": "A 2-3 sentence explanation of the visual traits (leaf shape, venation, color, flower structure, texture) that led to this identification. This is the Explainable AI (XAI) layer.",
  "edibility_status": "edible | edible_with_preparation | toxic | unknown",
  "safety_warnings": "Any warnings about toxic look-alikes, required preparation, or contra-indications.",
  "preparation_notes": "Traditional Nigerian preparation methods if known, otherwise general preparation advice.",
  "habitat": "Typical habitat and growing conditions in Nigeria.",
  "nutritional_highlights": "Key nutritional benefits if edible."
}

REGIONAL FOCUS: Prioritize Nigerian and West African species. If the plant matches a known Nigerian edible species, mention its local Nigerian names (Igbo, Hausa, Yoruba) if you know them.
''';

  /// Initialize the Gemini model with the stored API key.
  Future<bool> initialize() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final apiKey = prefs.getString('gemini_api_key');
      if (apiKey == null || apiKey.isEmpty) return false;

      _model = GenerativeModel(
        model: 'gemini-2.5-flash',
        apiKey: apiKey,
        systemInstruction: Content.system(_systemInstruction),
        generationConfig: GenerationConfig(
          temperature: 0.3, // Low temperature for factual accuracy
          maxOutputTokens: 4096,
          responseMimeType: 'application/json',
        ),
      );
      return true;
    } catch (e) {
      debugPrint('Gemini initialization failed: $e');
      return false;
    }
  }

  /// Check whether an API key is configured.
  Future<bool> hasApiKey() async {
    final prefs = await SharedPreferences.getInstance();
    final key = prefs.getString('gemini_api_key');
    return key != null && key.isNotEmpty;
  }

  /// Save a new API key and reinitialize the model.
  Future<void> setApiKey(String key) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('gemini_api_key', key.trim());
    await initialize();
  }

  /// Identify a plant from an image file.
  /// Returns a parsed Map of the identification result, or null on failure.
  Future<Map<String, dynamic>?> identifyPlant(File imageFile) async {
    if (_model == null) {
      final initialized = await initialize();
      if (!initialized) return null;
    }

    final imageBytes = await imageFile.readAsBytes();
    final mimeType = _getMimeType(imageFile.path);

    final content = Content.multi([
      TextPart('Identify this plant. Focus on Nigerian/West African species if applicable. '
          'Analyze the leaf shape, venation, color, texture, and any visible flowers or fruits. '
          'Respond with ONLY valid JSON.'),
      DataPart(mimeType, imageBytes),
    ]);

    int attempts = 0;
    const maxAttempts = 3;
    dynamic lastError;

    while (attempts < maxAttempts) {
      attempts++;
      try {
        final response = await _model!.generateContent([content]);
        final text = response.text;

        if (text == null || text.isEmpty) {
          throw Exception('Model returned empty response');
        }

        // Parse the JSON response
        final jsonStr = _extractJson(text);
        return jsonDecode(jsonStr) as Map<String, dynamic>;
      } catch (e) {
        lastError = e;
        debugPrint('Plant identification attempt $attempts failed: $e');
        if (attempts < maxAttempts) {
          await Future.delayed(Duration(seconds: 2 * attempts));
        }
      }
    }

    debugPrint('Plant identification failed after $maxAttempts attempts: $lastError');
    
    if (lastError.toString().contains('Quota exceeded')) {
      throw Exception('Gemini API Rate Limit Exceeded: Please wait a minute before trying again.');
    }
    throw Exception('API Error: $lastError');
  }

  /// Determine MIME type from file extension.
  String _getMimeType(String path) {
    final ext = path.toLowerCase().split('.').last;
    switch (ext) {
      case 'png':
        return 'image/png';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'webp':
        return 'image/webp';
      case 'heic':
        return 'image/heic';
      default:
        return 'image/jpeg';
    }
  }

  /// Extract JSON from a response that might contain markdown code fences.
  String _extractJson(String text) {
    var cleaned = text.trim();
    if (cleaned.startsWith('```json')) {
      cleaned = cleaned.substring(7);
    } else if (cleaned.startsWith('```')) {
      cleaned = cleaned.substring(3);
    }
    if (cleaned.endsWith('```')) {
      cleaned = cleaned.substring(0, cleaned.length - 3);
    }
    // Handle potential trailing commas causing FormatException
    cleaned = cleaned.replaceAll(RegExp(r',\s*}'), '}').replaceAll(RegExp(r',\s*\]'), ']');
    return cleaned.trim();
  }
}
