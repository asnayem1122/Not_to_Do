import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../providers/routine_providers.dart';
import '../repositories/routine_repository.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import '../theme/app_theme.dart';
import '../../features/navigation/main_scaffold.dart';
import '../../features/onboarding/presentation/onboarding_screen.dart';
import 'app_logo.dart';

/// AppBootstrapWidget renders an immediate branded first frame to prevent
/// Android ActivityManagerService startup ANR timeouts on Honor & OEM hardware,
/// while initializing Hive persistence and platform services asynchronously.
class AppBootstrapWidget extends ConsumerStatefulWidget {
  const AppBootstrapWidget({super.key});

  @override
  ConsumerState<AppBootstrapWidget> createState() => _AppBootstrapWidgetState();
}

class _AppBootstrapWidgetState extends ConsumerState<AppBootstrapWidget> {
  bool _isInitialized = false;
  bool _hasCompletedOnboarding = false;
  String? _initError;

  @override
  void initState() {
    super.initState();
    _startBootstrapPipeline();
  }

  Future<void> _startBootstrapPipeline() async {
    final startTime = DateTime.now();

    try {
      // 1. Parallel Hive Box Opening & Repository Init with 4-second strict timeout
      final repository = HiveRoutineRepository();
      await repository.init().timeout(
        const Duration(seconds: 4),
        onTimeout: () {
          debugPrint('Hive initialization reached 4s deadline; continuing in safe mode.');
        },
      );

      // Read onboarding flag from Hive settings box
      _hasCompletedOnboarding = Hive.isBoxOpen('settings_box')
          ? Hive.box('settings_box').get('hasCompletedOnboarding', defaultValue: false)
          : false;

      // 2. Queue secondary heavy platform services non-blocking in post-frame microtask
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _warmupBackgroundServices(repository);
      });
    } catch (e, st) {
      debugPrint('Bootstrap initialization encountered error: $e\n$st');
      _initError = e.toString();
    } finally {
      // Ensure minimum 400ms display to prevent jarring screen flash, capped strictly at 5s
      final elapsed = DateTime.now().difference(startTime);
      const minDisplay = Duration(milliseconds: 400);
      if (elapsed < minDisplay) {
        await Future.delayed(minDisplay - elapsed);
      }

      if (mounted) {
        setState(() {
          _isInitialized = true;
        });
      }
    }
  }

  /// Initializes notification channels, exact alarms, and background schedules
  /// without ever blocking the UI or main application thread.
  void _warmupBackgroundServices(HiveRoutineRepository repository) {
    Future.microtask(() async {
      try {
        final notifService = ref.read(notificationServiceProvider);
        await notifService.initialize().timeout(
          const Duration(seconds: 3),
          onTimeout: () {
            debugPrint('Notification service warmup timed out (3s); skipping startup schedule.');
          },
        );

        final settings = repository.getSyncSettings();
        final allEvents = repository.getAllEvents();

        if (settings.classReminderAlerts) {
          await notifService
              .rescheduleAllActiveAlerts(
                events: allEvents,
                settings: settings,
              )
              .timeout(const Duration(seconds: 4));
        }
      } catch (e) {
        debugPrint('Background service warmup non-fatal error: $e');
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final themeMode = ref.watch(themeModeProvider);

    return MaterialApp(
      title: 'Not To Do Routine Tracker',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.lightTheme,
      darkTheme: AppTheme.darkTheme,
      themeMode: themeMode,
      home: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _isInitialized
            ? (_hasCompletedOnboarding
                ? const MainScaffold(key: ValueKey('main_scaffold'))
                : const OnboardingScreen(key: ValueKey('onboarding')))
            : _BootstrapSplashView(
                key: const ValueKey('splash_view'),
                error: _initError,
              ),
      ),
    );
  }
}

/// Lightweight, immediate first-frame splash view
class _BootstrapSplashView extends StatelessWidget {
  final String? error;

  const _BootstrapSplashView({super.key, this.error});

  @override
  Widget build(BuildContext context) {
    final customColors = AppColors.of(context);
    final theme = Theme.of(context);


    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Spacer(flex: 3),
              const AppLogo(size: 76),
              const SizedBox(height: 24),
              Text(
                'Not To Do',
                style: theme.textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.5,
                  color: customColors.textPrimary,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Academic Routine & Habit Protection',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: customColors.textSecondary,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const Spacer(flex: 2),
              SizedBox(
                width: 32,
                height: 32,
                child: CircularProgressIndicator(
                  strokeWidth: 2.5,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    customColors.primaryAccent,
                  ),
                ),
              ),
              const Spacer(flex: 1),
              Text(
                'Protected by Clarity Anti-Habit Engine',
                style: theme.textTheme.labelSmall?.copyWith(
                  color: customColors.textMuted,
                  letterSpacing: 0.2,
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
