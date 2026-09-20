import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'core/models/routine_models.dart';
import 'core/widgets/app_bootstrap_widget.dart';

Future<void> main() async {
  // 1. Ensure Flutter bindings are active
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Core error routing to prevent unhandled crashes
  FlutterError.onError = (FlutterErrorDetails details) {
    FlutterError.presentError(details);
    debugPrint('[FlutterError] ${details.exception}');
  };
  PlatformDispatcher.instance.onError = (Object error, StackTrace stack) {
    debugPrint('[PlatformDispatcher Error] $error\n$stack');
    return true; // prevent crash
  };

  // 3. Essential lightweight local storage setup (Hive path initialization)
  try {
    await Hive.initFlutter();
  } catch (e) {
    debugPrint('Hive.initFlutter error: $e');
  }

  // Register in-memory TypeAdapters (synchronous & lightweight)
  Hive.registerAdapter(AcademicEventTypeAdapter());
  Hive.registerAdapter(AcademicEventAdapter());
  Hive.registerAdapter(HabitTypeAdapter());
  Hive.registerAdapter(HabitItemAdapter());
  Hive.registerAdapter(TimelineBlockTypeAdapter());
  Hive.registerAdapter(TimelineBlockAdapter());

  // 4. Immediate launch of AppBootstrapWidget to guarantee first-frame render
  runApp(
    const ProviderScope(
      child: AppBootstrapWidget(),
    ),
  );
}
