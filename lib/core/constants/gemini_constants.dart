/// Centralized configuration for Google Gemini AI models.
/// Uses the latest active models (Gemini 3.6 Flash) supported by Google AI Studio.
class GeminiConstants {
  /// Primary fast multimodal & conversational model
  static const String primaryModel = 'gemini-3.6-flash';

  /// Secondary fallback model in case of temporary 503 high demand or regional spike
  static const String fallbackModel = 'gemini-3.8-flash';
}
