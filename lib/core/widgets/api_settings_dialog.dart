import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_generative_ai/google_generative_ai.dart';
import '../constants/gemini_constants.dart';
import '../services/api_key_service.dart';
import '../theme/app_colors.dart';

class ApiSettingsDialog extends ConsumerStatefulWidget {
  const ApiSettingsDialog({super.key});

  static Future<void> show(BuildContext context) {
    return showDialog(
      context: context,
      builder: (ctx) => const ApiSettingsDialog(),
    );
  }

  @override
  ConsumerState<ApiSettingsDialog> createState() => _ApiSettingsDialogState();
}

class _ApiSettingsDialogState extends ConsumerState<ApiSettingsDialog> {
  final _keyController = TextEditingController();
  bool _obscureKey = true;
  bool _isTesting = false;
  String? _testResult;
  bool _testSuccess = false;
  String? _currentlyActiveKey;

  @override
  void initState() {
    super.initState();
    _loadKey();
  }

  Future<void> _loadKey() async {
    final key = await ref.read(apiKeyServiceProvider).getApiKey();
    if (key != null && mounted) {
      final cleaned = ApiKeyService.cleanApiKey(key);
      _keyController.text = cleaned;
      setState(() {
        _currentlyActiveKey = cleaned;
      });
    }
  }

  @override
  void dispose() {
    _keyController.dispose();
    super.dispose();
  }

  Future<void> _pasteFromClipboard() async {
    try {
      final data = await Clipboard.getData(Clipboard.kTextPlain);
      if (data?.text != null && data!.text!.trim().isNotEmpty) {
        final cleaned = ApiKeyService.cleanApiKey(data.text!);
        _keyController.text = cleaned;
        setState(() {
          _testResult = null;
        });

        final validationError = ApiKeyService.validateApiKey(cleaned);
        if (validationError != null) {
          setState(() {
            _testResult = validationError;
            _testSuccess = false;
          });
        } else {
          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Gemini API key pasted and formatted from clipboard.'),
                behavior: SnackBarBehavior.floating,
                duration: Duration(seconds: 2),
              ),
            );
          }
        }
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Clipboard is empty. Copy your Gemini API key first.'),
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (_) {}
  }

  Future<void> _copyStudioUrl() async {
    await Clipboard.setData(
      const ClipboardData(text: 'https://aistudio.google.com/app/apikey'),
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Google AI Studio URL copied to clipboard!'),
          behavior: SnackBarBehavior.floating,
          duration: Duration(seconds: 2),
        ),
      );
    }
  }

  Future<void> _testKey() async {
    final rawKey = _keyController.text;
    final cleaned = ApiKeyService.cleanApiKey(rawKey);
    _keyController.text = cleaned;

    final validationError = ApiKeyService.validateApiKey(cleaned);
    if (validationError != null) {
      setState(() {
        _testResult = validationError;
        _testSuccess = false;
      });
      return;
    }

    setState(() {
      _isTesting = true;
      _testResult = null;
    });

    try {
      String? replyText;
      String testedModel = GeminiConstants.primaryModel;

      try {
        final model = GenerativeModel(
          model: testedModel,
          apiKey: cleaned,
        );
        final response = await model.generateContent([
          Content.text('Respond with only the word OK to verify connection.'),
        ]).timeout(const Duration(seconds: 10));
        replyText = response.text;
      } catch (err1) {
        final errStr = err1.toString().toLowerCase();
        if (errStr.contains('not found') ||
            errStr.contains('404') ||
            errStr.contains('no longer available') ||
            errStr.contains('503') ||
            errStr.contains('unavailable')) {
          testedModel = GeminiConstants.fallbackModel;
          final model2 = GenerativeModel(
            model: testedModel,
            apiKey: cleaned,
          );
          final response2 = await model2.generateContent([
            Content.text('Respond with only the word OK to verify connection.'),
          ]).timeout(const Duration(seconds: 10));
          replyText = response2.text;
        } else {
          rethrow;
        }
      }

      if (replyText != null && mounted) {
        // Auto-save the validated key immediately to Hive and SecureStorage
        await ref.read(geminiApiKeyProvider.notifier).saveKey(cleaned);

        setState(() {
          _isTesting = false;
          _testSuccess = true;
          _currentlyActiveKey = cleaned;
          _testResult =
              'Connection verified ($testedModel)! Key automatically saved & active across all features.';
        });
      }
    } catch (e) {
      if (mounted) {
        final err = e.toString();
        String friendlyMessage;
        if (err.contains('API_KEY_INVALID') ||
            err.contains('400') ||
            err.contains('invalid api key')) {
          friendlyMessage =
              'Invalid API key. Make sure you copied the entire key from Google AI Studio without extra symbols.';
        } else if (err.contains('PERMISSION_DENIED') || err.contains('403')) {
          friendlyMessage =
              'Permission denied. Ensure the Generative Language API is enabled for this Google Cloud project.';
        } else if (err.contains('RESOURCE_EXHAUSTED') || err.contains('429')) {
          friendlyMessage =
              'Rate limit reached on your free quota. Wait 30 seconds and try again.';
        } else if (err.contains('TimeoutException') ||
            err.contains('timed out')) {
          friendlyMessage =
              'Connection timed out. Google AI servers took too long. Check your internet connection.';
        } else if (err.contains('SocketException') ||
            err.contains('Failed host lookup') ||
            err.contains('Network is unreachable')) {
          friendlyMessage =
              'No internet connection. Please verify your Wi-Fi or mobile data.';
        } else {
          friendlyMessage = 'Verification failed: ${err.split('\n').first}';
        }

        setState(() {
          _isTesting = false;
          _testSuccess = false;
          _testResult = friendlyMessage;
        });
      }
    }
  }

  Future<void> _saveKey() async {
    final cleaned = ApiKeyService.cleanApiKey(_keyController.text);
    _keyController.text = cleaned;

    if (cleaned.isNotEmpty) {
      final validationError = ApiKeyService.validateApiKey(cleaned);
      if (validationError != null) {
        setState(() {
          _testResult = validationError;
          _testSuccess = false;
        });
        return;
      }
    }

    await ref.read(geminiApiKeyProvider.notifier).saveKey(cleaned);
    if (mounted) {
      Navigator.of(context).pop();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(cleaned.isEmpty
              ? 'Gemini API Key cleared.'
              : 'Gemini API Key saved and active.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  Future<void> _clearKey() async {
    await ref.read(geminiApiKeyProvider.notifier).removeKey();
    _keyController.clear();
    setState(() {
      _testResult = null;
      _currentlyActiveKey = null;
      _testSuccess = false;
    });
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Gemini API Key removed from persistent storage.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
    }
  }

  String _formatKeyPreview(String key) {
    if (key.length <= 10) return key;
    return '${key.substring(0, 6)}...${key.substring(key.length - 4)}';
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final customColors = AppColors.of(context);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: customColors.cardBackground,
      child: Container(
        padding: const EdgeInsets.all(24),
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: customColors.primaryFixed,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(
                      Icons.auto_awesome,
                      color: customColors.onPrimaryFixed,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Gemini AI Settings',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                            fontSize: 18,
                          ),
                        ),
                        Text(
                          'Bring Your Own Key (BYOK)',
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: customColors.textSecondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close, size: 20),
                    onPressed: () => Navigator.of(context).pop(),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Active Key Status Badge
              if (_currentlyActiveKey != null &&
                  _currentlyActiveKey!.isNotEmpty) ...[
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  decoration: BoxDecoration(
                    color: Colors.green.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: Colors.green.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.check_circle_rounded,
                          color: Colors.green, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          'Active Key: ${_formatKeyPreview(_currentlyActiveKey!)}',
                          style: const TextStyle(
                            color: Colors.green,
                            fontWeight: FontWeight.w700,
                            fontSize: 12,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 14),
              ],

              // Description banner
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: customColors.cardBorder),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.lock_outline,
                      size: 18,
                      color: customColors.primaryAccent,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Stored locally on your device in persistent encrypted storage. Only used for your multimodal routine scanner, AI routine guard, and schedule repairs.',
                        style: theme.textTheme.bodySmall?.copyWith(
                          fontSize: 11,
                          height: 1.4,
                          color: customColors.textSecondary,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Input Header with 1-Tap Paste Button
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'GEMINI API KEY',
                    style: theme.textTheme.labelSmall?.copyWith(
                      color: customColors.textMuted,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5,
                    ),
                  ),
                  InkWell(
                    onTap: _pasteFromClipboard,
                    borderRadius: BorderRadius.circular(6),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.content_paste_rounded,
                              size: 14, color: customColors.primaryAccent),
                          const SizedBox(width: 4),
                          Text(
                            'Paste Key',
                            style: TextStyle(
                              color: customColors.primaryAccent,
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),

              // Key Input Field
              TextField(
                controller: _keyController,
                obscureText: _obscureKey,
                onChanged: (_) {
                  if (_testResult != null) {
                    setState(() => _testResult = null);
                  }
                },
                decoration: InputDecoration(
                  hintText: 'AIzaSy...',
                  filled: true,
                  fillColor: theme.colorScheme.surfaceContainerHighest
                      .withValues(alpha: 0.5),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide(color: customColors.cardBorder),
                  ),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        tooltip: _obscureKey ? 'Show Key' : 'Hide Key',
                        icon: Icon(
                          _obscureKey
                              ? Icons.visibility_outlined
                              : Icons.visibility_off_outlined,
                          size: 18,
                        ),
                        onPressed: () =>
                            setState(() => _obscureKey = !_obscureKey),
                      ),
                      IconButton(
                        tooltip: 'Clear input',
                        icon: const Icon(Icons.clear, size: 18),
                        onPressed: () {
                          _keyController.clear();
                          setState(() => _testResult = null);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 10),

              // Link to Google AI Studio
              Row(
                children: [
                  Icon(Icons.info_outline,
                      size: 14, color: customColors.academic),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      'Get free key at aistudio.google.com',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: customColors.academic,
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  InkWell(
                    onTap: _copyStudioUrl,
                    child: Padding(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 6, vertical: 2),
                      child: Text(
                        'Copy URL ↗',
                        style: TextStyle(
                          color: customColors.primaryAccent,
                          fontSize: 11,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Action Row: Test Connection & Clear Key
              Row(
                children: [
                  ElevatedButton.icon(
                    onPressed: _isTesting ? null : _testKey,
                    icon: _isTesting
                        ? const SizedBox(
                            width: 14,
                            height: 14,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.bolt, size: 16),
                    label: Text(
                        _isTesting ? 'Verifying...' : 'Test & Auto-Save'),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: customColors.primaryAccent,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 16, vertical: 10),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),
                    ),
                  ),
                  const Spacer(),
                  TextButton.icon(
                    onPressed: _clearKey,
                    icon: Icon(Icons.delete_outline,
                        size: 16, color: customColors.antiHabit),
                    label: Text(
                      'Clear Key',
                      style: TextStyle(
                        color: customColors.antiHabit,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),

              // Test Result Banner
              if (_testResult != null) ...[
                const SizedBox(height: 14),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    color: _testSuccess
                        ? Colors.green.withValues(alpha: 0.1)
                        : Colors.red.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: _testSuccess
                          ? Colors.green.withValues(alpha: 0.3)
                          : Colors.red.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        _testSuccess
                            ? Icons.check_circle_rounded
                            : Icons.error_outline_rounded,
                        size: 18,
                        color: _testSuccess ? Colors.green : Colors.red,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _testResult!,
                          style: theme.textTheme.bodySmall?.copyWith(
                            color: _testSuccess
                                ? Colors.green.shade800
                                : Colors.red.shade800,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 20),

              // Dialog Footer Buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: Text(_testSuccess ? 'Close' : 'Cancel'),
                  ),
                  const SizedBox(width: 10),
                  if (_testSuccess)
                    ElevatedButton(
                      onPressed: () => Navigator.of(context).pop(),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: customColors.primaryAccent,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                            horizontal: 24, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('OK'),
                    )
                  else
                    OutlinedButton(
                      onPressed: _saveKey,
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 18, vertical: 10),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      child: const Text('Save Changes'),
                    ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
