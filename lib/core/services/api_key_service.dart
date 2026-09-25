import 'dart:io' show File;
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:hive/hive.dart';

class ApiKeyService {
  static const String _geminiStorageKey = 'gemini_api_key';
  static const String _settingsBoxName = 'settings_box';
  final FlutterSecureStorage _storage;

  ApiKeyService({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
                resetOnError: true,
              ),
            );

  /// Global static in-memory cache shared across all instances
  static String? _cachedKey;

  /// Reads a GEMINI_API_KEY from a local .env file if running locally.
  static String? _loadKeyFromLocalEnv() {
    try {
      if (!kIsWeb) {
        final file = File('.env');
        if (file.existsSync()) {
          final lines = file.readAsLinesSync();
          for (final line in lines) {
            final trimmed = line.trim();
            if (trimmed.isEmpty || trimmed.startsWith('#')) continue;
            if (trimmed.startsWith('GEMINI_API_KEY=')) {
              final val = trimmed.substring('GEMINI_API_KEY='.length).trim();
              final cleaned = cleanApiKey(val);
              if (cleaned.isNotEmpty) return cleaned;
            }
          }
        }
      }
    } catch (_) {}
    return null;
  }

  /// Sanitizes any pasted or raw API key by stripping quotes, whitespace,
  /// and variable prefix declarations (e.g., GEMINI_API_KEY=, export, key=).
  static String cleanApiKey(String raw) {
    var cleaned = raw.trim();
    // Remove smart quotes and regular quotes
    if ((cleaned.startsWith('"') && cleaned.endsWith('"')) ||
        (cleaned.startsWith("'") && cleaned.endsWith("'")) ||
        (cleaned.startsWith('“') && cleaned.endsWith('”')) ||
        (cleaned.startsWith('‘') && cleaned.endsWith('’'))) {
      cleaned = cleaned.substring(1, cleaned.length - 1).trim();
    }

    // Strip common env prefixes like export GEMINI_API_KEY= or GEMINI_API_KEY=
    final prefixes = [
      'export GEMINI_API_KEY=',
      'GEMINI_API_KEY=',
      'export API_KEY=',
      'API_KEY=',
      'apiKey=',
      'key=',
    ];
    for (final prefix in prefixes) {
      if (cleaned.toUpperCase().startsWith(prefix.toUpperCase())) {
        cleaned = cleaned.substring(prefix.length).trim();
        // Check for quotes again after removing prefix
        if ((cleaned.startsWith('"') && cleaned.endsWith('"')) ||
            (cleaned.startsWith("'") && cleaned.endsWith("'"))) {
          cleaned = cleaned.substring(1, cleaned.length - 1).trim();
        }
        break;
      }
    }

    // Strip internal carriage returns and newlines
    cleaned = cleaned.replaceAll('\r', '').replaceAll('\n', '').trim();
    return cleaned;
  }

  /// Validates format of the API key
  static String? validateApiKey(String raw) {
    final clean = cleanApiKey(raw);
    if (clean.isEmpty) {
      return 'API key cannot be empty.';
    }
    if (clean.startsWith('sk-ant-')) {
      return 'This appears to be an Anthropic Claude key. Please use a Google Gemini key.';
    }
    if (clean.startsWith('sk-')) {
      return 'This appears to be an OpenAI key. Please use a Google Gemini key from aistudio.google.com.';
    }
    if (clean.contains(' ')) {
      return 'API key should not contain spaces.';
    }
    if (clean.length < 25) {
      return 'API key appears too short (Gemini keys are typically 39-55 characters).';
    }
    return null;
  }

  /// Retrieves the saved Gemini API key.
  /// Hierarchy:
  /// 1. In-memory static cache
  /// 2. Hive persistent storage (instant disk I/O, works on all platforms)
  /// 3. FlutterSecureStorage (hardware Keystore)
  /// 4. Compile-time --dart-define=GEMINI_API_KEY or --dart-define-from-file=.env
  /// 5. Local .env file on disk (development mode, ignored by git)
  Future<String?> getApiKey() async {
    if (_cachedKey != null && _cachedKey!.trim().isNotEmpty) {
      return _cachedKey;
    }

    // 1. Try Hive settings box (reliable across Android, iOS, Windows, Desktop, Web)
    try {
      Box? box;
      if (Hive.isBoxOpen(_settingsBoxName)) {
        box = Hive.box(_settingsBoxName);
      } else {
        try {
          box = await Hive.openBox(_settingsBoxName)
              .timeout(const Duration(seconds: 2));
        } catch (_) {
          box = null;
        }
      }
      if (box != null) {
        final hiveKey = box.get(_geminiStorageKey) as String?;
        if (hiveKey != null && hiveKey.trim().isNotEmpty) {
          _cachedKey = cleanApiKey(hiveKey);
          return _cachedKey;
        }
      }
    } catch (e) {
      debugPrint('Hive getApiKey fallback: $e');
    }

    // 2. Try Secure Storage
    try {
      final savedKey = await _storage
          .read(key: _geminiStorageKey)
          .timeout(const Duration(seconds: 2), onTimeout: () => null);
      if (savedKey != null && savedKey.trim().isNotEmpty) {
        _cachedKey = cleanApiKey(savedKey);
        // Resync to Hive
        _syncToHive(_cachedKey!);
        return _cachedKey;
      }
    } catch (_) {
      // Keystore unavailable / error
    }

    // 3. Compile-time fallback (--dart-define or --dart-define-from-file=.env)
    const envKey = String.fromEnvironment('GEMINI_API_KEY', defaultValue: '');
    if (envKey.trim().isNotEmpty) {
      _cachedKey = cleanApiKey(envKey);
      _syncToHive(_cachedKey!);
      return _cachedKey;
    }

    // 4. Local .env file fallback (for local development & debugging)
    final localEnvKey = _loadKeyFromLocalEnv();
    if (localEnvKey != null && localEnvKey.isNotEmpty) {
      _cachedKey = localEnvKey;
      _syncToHive(_cachedKey!);
      return _cachedKey;
    }

    return null;
  }

  void _syncToHive(String key) {
    try {
      if (Hive.isBoxOpen(_settingsBoxName)) {
        Hive.box(_settingsBoxName).put(_geminiStorageKey, key);
      }
    } catch (_) {}
  }

  /// Saves the Gemini API key with dual-layer persistence (Hive + SecureStorage).
  Future<void> setApiKey(String key) async {
    final cleaned = cleanApiKey(key);
    _cachedKey = cleaned.isEmpty ? null : cleaned;

    if (cleaned.isEmpty) {
      await clearApiKey();
      return;
    }

    // 1. Save to Hive immediately (synchronous local disk guarantee)
    try {
      if (Hive.isBoxOpen(_settingsBoxName)) {
        await Hive.box(_settingsBoxName).put(_geminiStorageKey, cleaned);
      } else {
        final box = await Hive.openBox(_settingsBoxName);
        await box.put(_geminiStorageKey, cleaned);
      }
    } catch (e) {
      debugPrint('Hive setApiKey fallback: $e');
    }

    // 2. Mirror to FlutterSecureStorage
    try {
      await _storage
          .write(key: _geminiStorageKey, value: cleaned)
          .timeout(const Duration(seconds: 2));
    } catch (_) {}
  }

  /// Clears the saved Gemini API key from both storage layers.
  Future<void> clearApiKey() async {
    _cachedKey = null;

    try {
      if (Hive.isBoxOpen(_settingsBoxName)) {
        await Hive.box(_settingsBoxName).delete(_geminiStorageKey);
      }
    } catch (_) {}

    try {
      await _storage
          .delete(key: _geminiStorageKey)
          .timeout(const Duration(seconds: 2));
    } catch (_) {}
  }

  /// Checks if a valid API key is present either in storage or environment.
  Future<bool> hasApiKey() async {
    final key = await getApiKey();
    return key != null && key.isNotEmpty;
  }
}

/// Provider for ApiKeyService singleton
final apiKeyServiceProvider = Provider<ApiKeyService>((ref) {
  return ApiKeyService();
});

/// Reactive notifier for Gemini API key
class GeminiApiKeyNotifier extends StateNotifier<AsyncValue<String?>> {
  final ApiKeyService _service;

  GeminiApiKeyNotifier(this._service) : super(const AsyncValue.loading()) {
    refreshKey();
  }

  Future<void> refreshKey() async {
    try {
      final key = await _service.getApiKey();
      state = AsyncValue.data(key);
    } catch (e, st) {
      state = AsyncValue.error(e, st);
    }
  }

  Future<void> saveKey(String key) async {
    await _service.setApiKey(key);
    final current = await _service.getApiKey();
    state = AsyncValue.data(current);
  }

  Future<void> removeKey() async {
    await _service.clearApiKey();
    final current = await _service.getApiKey();
    state = AsyncValue.data(current);
  }
}

/// Provider for the active Gemini API key
final geminiApiKeyProvider =
    StateNotifierProvider<GeminiApiKeyNotifier, AsyncValue<String?>>((ref) {
  final service = ref.watch(apiKeyServiceProvider);
  return GeminiApiKeyNotifier(service);
});
