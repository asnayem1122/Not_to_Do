import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:flutter/material.dart';
import 'package:not_to_do/features/defense/presentation/curfew_sentry_overlay.dart';

import 'dart:io';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('hive_curfew_');
    Hive.init(tempDir.path);
    final box = await Hive.openBox('settings_box');
    await box.put('curfewEnabled', true);
  });

  tearDownAll(() async {
    await Hive.close();
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  test('CurfewSentryOverlay logic handles cross-midnight bounds', () {
    // Start 22:30 (1350), End 04:00 (240)
    expect(CurfewSentryOverlay.isCurfewLocked(1380, 1350, 240), isTrue); // 23:00 is locked
    expect(CurfewSentryOverlay.isCurfewLocked(720, 1350, 240), isFalse); // 12:00 is unlocked
    expect(CurfewSentryOverlay.isCurfewLocked(120, 1350, 240), isTrue);  // 02:00 is locked
  });

  test('CurfewSentryOverlay logic handles same-day bounds', () {
    // Start 10:00 (600), End 15:00 (900)
    expect(CurfewSentryOverlay.isCurfewLocked(720, 600, 900), isTrue); // 12:00 is locked
    expect(CurfewSentryOverlay.isCurfewLocked(960, 600, 900), isFalse); // 16:00 is unlocked
    expect(CurfewSentryOverlay.isCurfewLocked(300, 600, 900), isFalse); // 05:00 is unlocked
  });

  testWidgets('CurfewSentryOverlay bypasses lock if enableCurfew is false', (tester) async {
    final box = Hive.box('settings_box');
    await box.put('curfewEnabled', false);
    
    await tester.pumpWidget(
      const MaterialApp(
        home: Scaffold(
          body: CurfewSentryOverlay(
            child: Text('Unlocked Content'),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));
    expect(find.text('Unlocked Content'), findsOneWidget);
    expect(find.text('BEDTIME CURFEW'), findsNothing);
  });
}
