import 'dart:io';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive/hive.dart';
import 'package:not_to_do/core/services/api_key_service.dart';
import 'package:not_to_do/core/constants/gemini_constants.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late Directory tempDir;

  setUpAll(() {
    tempDir = Directory.systemTemp.createTempSync('hive_test');
    Hive.init(tempDir.path);
  });

  tearDownAll(() {
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  group('ApiKeyService and GeminiConstants Tests', () {
    test('GeminiConstants points to active Gemini 3.6 Flash', () {
      expect(GeminiConstants.primaryModel, 'gemini-3.6-flash');
      expect(GeminiConstants.fallbackModel, 'gemini-3.8-flash');
    });

    test('cleanApiKey removes quotes and env prefixes', () {
      expect(ApiKeyService.cleanApiKey(' "AIzaSyTest" '), 'AIzaSyTest');
      expect(ApiKeyService.cleanApiKey('export GEMINI_API_KEY="AQ.TestKey123"'), 'AQ.TestKey123');
      expect(ApiKeyService.cleanApiKey('GEMINI_API_KEY=AQ.TestKey123'), 'AQ.TestKey123');
      expect(ApiKeyService.cleanApiKey('AQ.DummyTestKeyDummyTestKeyDummyTestKey1234\n'), 'AQ.DummyTestKeyDummyTestKeyDummyTestKey1234');
    });

    test('validateApiKey validates new AQ. keys and detects invalid formats', () {
      // Valid AQ key
      expect(ApiKeyService.validateApiKey('AQ.DummyTestKeyDummyTestKeyDummyTestKey1234'), isNull);
      // Empty key
      expect(ApiKeyService.validateApiKey(''), isNotNull);
      // Claude key
      expect(ApiKeyService.validateApiKey('sk-ant-api03-123456789012345678901234567890'), contains('Claude'));
      // OpenAI key
      expect(ApiKeyService.validateApiKey('sk-proj-123456789012345678901234567890'), contains('OpenAI'));
      // Too short
      expect(ApiKeyService.validateApiKey('AQ.short'), contains('too short'));
    });

    test('getApiKey reads from a local .env file when present (dev fallback)',
        () async {
      // Self-contained test: writes a throwaway .env with a dummy key so the
      // repository itself never needs to ship a real secret. Any pre-existing
      // developer .env is backed up and restored afterwards.
      const dummyKey = 'AQ.DummyLocalEnvLoaderKey1234567890abcdef';
      final envFile = File('.env');
      final existed = envFile.existsSync();
      final backup = existed ? envFile.readAsStringSync() : null;
      envFile.writeAsStringSync('GEMINI_API_KEY=$dummyKey');
      addTearDown(() {
        if (existed) {
          envFile.writeAsStringSync(backup!);
        } else if (envFile.existsSync()) {
          envFile.deleteSync();
        }
      });

      final service = ApiKeyService();
      final key = await service.getApiKey();
      expect(key, dummyKey);

      // Reset the shared in-memory cache so later suites start clean.
      await service.clearApiKey();
    });
  });
}
