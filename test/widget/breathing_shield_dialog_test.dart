import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:not_to_do/features/defense/presentation/breathing_shield_dialog.dart';

import 'dart:io';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('hive_breathing_');
    Hive.init(tempDir.path);
    final box = await Hive.openBox('settings_box');
    await box.put('breathingCycleSeconds', 2);
  });

  tearDownAll(() async {
    await Hive.close();
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  testWidgets('BreathingShieldDialog countdown and proceed logic', (tester) async {
    bool proceeded = false;

    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Builder(
            builder: (context) => ElevatedButton(
              onPressed: () {
                BreathingShieldDialog.show(
                  context,
                  title: 'Test Shield',
                  warningText: 'Are you sure?',
                  durationSeconds: 2,
                  onProceed: () {
                    proceeded = true;
                  },
                );
              },
              child: const Text('Show Dialog'),
            ),
          ),
        ),
      ),
    );

    // Open the dialog
    await tester.tap(find.text('Show Dialog'));
    await tester.pump(); // Start opening
    await tester.pump(const Duration(milliseconds: 500)); // Finish opening

    expect(find.text('Test Shield'), findsOneWidget);
    
    // Check initial button state (disabled)
    final breakButton = find.widgetWithText(TextButton, 'Break Shield');
    expect(breakButton, findsOneWidget);
    
    // Tap should not work
    await tester.tap(breakButton);
    expect(proceeded, isFalse);

    // Advance 1 second
    await tester.pump(const Duration(seconds: 1));
    expect(proceeded, isFalse);

    // Advance 1 more second
    await tester.pump(const Duration(seconds: 1));
    
    // Advance enough time to let the UI update and countdown finish
    await tester.pump(const Duration(milliseconds: 100));

    // Now it should be clickable
    await tester.tap(find.widgetWithText(TextButton, 'Break Shield'));
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(proceeded, isTrue);
  });
}
