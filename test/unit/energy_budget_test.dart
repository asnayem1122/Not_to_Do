import 'package:flutter_test/flutter_test.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:not_to_do/core/models/routine_models.dart';
import 'package:not_to_do/features/today/presentation/widgets/daily_energy_gauge.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:not_to_do/core/providers/routine_providers.dart';
import 'package:flutter/material.dart';

import 'dart:io';

void main() {
  late Directory tempDir;

  setUpAll(() async {
    tempDir = Directory.systemTemp.createTempSync('hive_energy_');
    Hive.init(tempDir.path);
    final box = await Hive.openBox('settings_box');
    await box.put('maxDailyEnergy', 20.0);
    await box.put('burnoutThreshold', -10.0);
  });

  tearDownAll(() async {
    await Hive.close();
    try {
      tempDir.deleteSync(recursive: true);
    } catch (_) {}
  });

  testWidgets('DailyEnergyGauge computes drain and recharge correctly', (tester) async {
    final mockBlocks = [
      TimelineBlock(
        id: '1',
        title: 'Sleep',
        startTime: '22:00',
        endTime: '06:00',
        type: TimelineBlockType.routineFocus,
        energyCost: 5, // Recharge
      ),
      TimelineBlock(
        id: '2',
        title: 'Study',
        startTime: '08:00',
        endTime: '10:00',
        type: TimelineBlockType.academicClass,
        energyCost: -15, // Drain
      ),
    ];

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          filteredTimelineProvider.overrideWith((ref) => mockBlocks),
        ],
        child: const MaterialApp(
          home: Scaffold(
            body: DailyEnergyGauge(),
          ),
        ),
      ),
    );

    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.text('-15 Drain'), findsOneWidget);
    expect(find.text('+5 Recharge'), findsOneWidget);
    // Net energy = 5 - 15 = -10. Burnout risk threshold is -10.0
    // so netEnergy < burnoutThreshold is false (-10 < -10 is false)
    // Wait, warning threshold is burnoutThreshold / 2 = -5.0
    // netEnergy < warningThreshold (-10 < -5) is true
    expect(find.text('Energy Deficit: Need Rest'), findsOneWidget);
  });
}
