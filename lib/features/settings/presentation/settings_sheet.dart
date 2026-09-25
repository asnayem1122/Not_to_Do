import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:hive_flutter/hive_flutter.dart';
import '../../../core/theme/app_colors.dart';

class SettingsSheet extends StatefulWidget {
  const SettingsSheet({super.key});

  static void show(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => const SettingsSheet(),
    );
  }

  @override
  State<SettingsSheet> createState() => _SettingsSheetState();
}

class _SettingsSheetState extends State<SettingsSheet> {
  late Box _settingsBox;
  
  bool _curfewEnabled = true;
  int _curfewStartMins = 1350; // 22:30
  int _curfewEndMins = 240; // 04:00

  bool _shieldEnabled = true;
  int _shieldDuration = 15;
  int _breathingCycleSeconds = 4;

  double _maxDailyEnergy = 20.0;
  double _burnoutThreshold = -10.0;

  @override
  void initState() {
    super.initState();
    _settingsBox = Hive.box('settings_box');
    
    _curfewEnabled = _settingsBox.get('curfewEnabled', defaultValue: true);
    _curfewStartMins = _settingsBox.get('curfewStartMins', defaultValue: 1350);
    _curfewEndMins = _settingsBox.get('curfewEndMins', defaultValue: 240);
    
    _shieldEnabled = _settingsBox.get('breathingShieldEnabled', defaultValue: true);
    _shieldDuration = _settingsBox.get('breathingShieldDuration', defaultValue: 15);
    _breathingCycleSeconds = _settingsBox.get('breathingCycleSeconds', defaultValue: 4);
    
    _maxDailyEnergy = _settingsBox.get('maxDailyEnergy', defaultValue: 20.0);
    _burnoutThreshold = _settingsBox.get('burnoutThreshold', defaultValue: -10.0);
  }

  void _saveSettings() {
    _settingsBox.put('curfewEnabled', _curfewEnabled);
    _settingsBox.put('curfewStartMins', _curfewStartMins);
    _settingsBox.put('curfewEndMins', _curfewEndMins);
    
    _settingsBox.put('breathingShieldEnabled', _shieldEnabled);
    _settingsBox.put('breathingShieldDuration', _shieldDuration);
    _settingsBox.put('breathingCycleSeconds', _breathingCycleSeconds);
    
    _settingsBox.put('maxDailyEnergy', _maxDailyEnergy);
    _settingsBox.put('burnoutThreshold', _burnoutThreshold);
  }

  Future<void> _pickTime(BuildContext context, bool isStart) async {
    final initialMins = isStart ? _curfewStartMins : _curfewEndMins;
    final initialTime = TimeOfDay(hour: initialMins ~/ 60, minute: initialMins % 60);
    
    final picked = await showTimePicker(
      context: context,
      initialTime: initialTime,
    );
    
    if (picked != null) {
      setState(() {
        if (isStart) {
          _curfewStartMins = picked.hour * 60 + picked.minute;
        } else {
          _curfewEndMins = picked.hour * 60 + picked.minute;
        }
        _saveSettings();
      });
    }
  }

  String _formatTime(int mins) {
    final hour = (mins ~/ 60).toString().padLeft(2, '0');
    final minute = (mins % 60).toString().padLeft(2, '0');
    return '$hour:$minute';
  }

  @override
  Widget build(BuildContext context) {
    final customColors = AppColors.of(context);
    final theme = Theme.of(context);

    return Container(
      padding: EdgeInsets.only(
        left: 24,
        right: 24,
        top: 24,
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
      ),
      decoration: BoxDecoration(
        color: customColors.canvasBackground,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Defense Controls',
                style: theme.textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: customColors.textPrimary,
                ),
              ),
              IconButton(
                icon: const Icon(Icons.close),
                color: customColors.textSecondary,
                onPressed: () => Navigator.of(context).pop(),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          // Bedtime Curfew
          SwitchListTile(
            title: const Text('Bedtime Curfew Sentry'),
            subtitle: const Text('Blocks the app late at night to protect sleep.'),
            value: _curfewEnabled,
            activeThumbColor: customColors.primaryAccent,
            onChanged: (val) {
              setState(() {
                _curfewEnabled = val;
                _saveSettings();
              });
            },
            contentPadding: EdgeInsets.zero,
          ),
          if (_curfewEnabled)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.bedtime, size: 16),
                      label: Text('Starts: ${_formatTime(_curfewStartMins)}'),
                      onPressed: () => _pickTime(context, true),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.wb_sunny, size: 16),
                      label: Text('Ends: ${_formatTime(_curfewEndMins)}'),
                      onPressed: () => _pickTime(context, false),
                    ),
                  ),
                ],
              ),
            ),
            
          const Divider(height: 32),
          
          // Breathing Shield
          SwitchListTile(
            title: const Text('Breathing Shield'),
            subtitle: const Text('Requires a mindful pause before deleting habits.'),
            value: _shieldEnabled,
            activeThumbColor: customColors.primaryAccent,
            onChanged: (val) {
              setState(() {
                _shieldEnabled = val;
                _saveSettings();
              });
            },
            contentPadding: EdgeInsets.zero,
          ),
          if (_shieldEnabled)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  Text('Shield Duration: $_shieldDuration s',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: customColors.textSecondary,
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: _shieldDuration.toDouble(),
                      min: 5,
                      max: 60,
                      divisions: 11,
                      activeColor: customColors.primaryAccent,
                      onChanged: (val) {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _shieldDuration = val.toInt();
                        });
                      },
                      onChangeEnd: (val) {
                        _saveSettings();
                      },
                    ),
                  ),
                ],
              ),
            ),
          if (_shieldEnabled)
            Padding(
              padding: const EdgeInsets.only(top: 8.0),
              child: Row(
                children: [
                  Text('Cycle Speed: ${_breathingCycleSeconds}s',
                    style: theme.textTheme.bodyMedium?.copyWith(
                      color: customColors.textSecondary,
                    ),
                  ),
                  Expanded(
                    child: Slider(
                      value: _breathingCycleSeconds.toDouble(),
                      min: 2,
                      max: 8,
                      divisions: 6,
                      activeColor: customColors.primaryAccent,
                      onChanged: (val) {
                        HapticFeedback.selectionClick();
                        setState(() {
                          _breathingCycleSeconds = val.toInt();
                        });
                      },
                      onChangeEnd: (val) {
                        _saveSettings();
                      },
                    ),
                  ),
                ],
              ),
            ),
            
          const Divider(height: 32),
          
          // Energy Budget Sensitivity
          Text(
            'Energy Budget Sensitivity',
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.bold,
              color: customColors.textPrimary,
            ),
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Text('Max Daily Drain: ${_maxDailyEnergy.toInt()}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: customColors.textSecondary,
                ),
              ),
              Expanded(
                child: Slider(
                  value: _maxDailyEnergy,
                  min: 10,
                  max: 50,
                  divisions: 8, // 5 steps (10, 15, 20...) - wait, divisions = (50-10)/5 = 40/5 = 8
                  activeColor: customColors.warning,
                  onChanged: (val) {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _maxDailyEnergy = val;
                    });
                  },
                  onChangeEnd: (val) => _saveSettings(),
                ),
              ),
            ],
          ),
          Row(
            children: [
              Text('Burnout Threshold: ${_burnoutThreshold.toInt()}',
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: customColors.textSecondary,
                ),
              ),
              Expanded(
                child: Slider(
                  value: _burnoutThreshold,
                  min: -30,
                  max: -5,
                  divisions: 25,
                  activeColor: customColors.antiHabit,
                  onChanged: (val) {
                    HapticFeedback.selectionClick();
                    setState(() {
                      _burnoutThreshold = val;
                    });
                  },
                  onChangeEnd: (val) => _saveSettings(),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
