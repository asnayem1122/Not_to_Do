import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/routine_providers.dart';
import '../services/api_key_service.dart';
import '../services/calendar_sync_service.dart';
import '../services/notification_service.dart';
import '../theme/app_colors.dart';
import 'api_settings_dialog.dart';
import 'app_logo.dart';
import '../../features/settings/presentation/settings_sheet.dart';

class AppTopHeader extends ConsumerWidget implements PreferredSizeWidget {
  final String subtitle;
  final VoidCallback? onNotificationTap;
  final VoidCallback? onProfileTap;

  const AppTopHeader({
    super.key,
    required this.subtitle,
    this.onNotificationTap,
    this.onProfileTap,
  });

  @override
  Size get preferredSize => const Size.fromHeight(68);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final customColors = AppColors.of(context);
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final syncSettings = ref.watch(syncSettingsProvider);
    final hasApiKey =
        ref.watch(geminiApiKeyProvider).valueOrNull?.isNotEmpty ?? false;
    final heroClass = ref.watch(heroClassProvider);

    return SafeArea(
      bottom: false,
      child: Container(
        height: 68,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: theme.scaffoldBackgroundColor.withValues(alpha: 0.95),
          border: Border(
            bottom: BorderSide(
              color: customColors.cardBorder.withValues(alpha: 0.5),
              width: 1,
            ),
          ),
        ),
        child: Row(
          children: [
            // Logo with multi-tier fallback safety
            const AppLogo(size: 34),
            const SizedBox(width: 10),

            // Title, Subtitle, and Live Sync Dot
            Expanded(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        'Not To Do',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w800,
                          fontSize: 16,
                          letterSpacing: -0.2,
                        ),
                      ),
                      const SizedBox(width: 8),
                      InkWell(
                        onTap: () async {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(
                              content: Text('Syncing with Google Calendar...'),
                              duration: Duration(milliseconds: 900),
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                          final calService = ref.read(calendarSyncServiceProvider);
                          final notifService = ref.read(notificationServiceProvider);
                          final timelineNotifier =
                              ref.read(timelineBlocksProvider.notifier);
                          final academicNotifier =
                              ref.read(academicEventsProvider.notifier);

                          final result = await ref
                              .read(syncSettingsProvider.notifier)
                              .performTwoWaySync(
                                calService: calService,
                                notifService: notifService,
                                timelineNotifier: timelineNotifier,
                                academicNotifier: academicNotifier,
                              );

                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(
                                content: Text(
                                  'Synced ${result.exportedCount} classes to ${result.calendarName ?? "Calendar"} • ${result.importedBlocks.length} external events imported',
                                ),
                                backgroundColor: customColors.primaryAccent,
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        },
                        borderRadius: BorderRadius.circular(6),
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 6, vertical: 2),
                          decoration: BoxDecoration(
                            color: (syncSettings.is2WayLiveSyncActive
                                    ? customColors.primaryAccent
                                    : customColors.textMuted)
                                .withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Container(
                                width: 5,
                                height: 5,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: syncSettings.is2WayLiveSyncActive
                                      ? customColors.primaryAccent
                                      : customColors.textMuted,
                                  boxShadow: syncSettings.is2WayLiveSyncActive
                                      ? [
                                          BoxShadow(
                                            color: customColors.primaryAccent
                                                .withValues(alpha: 0.6),
                                            blurRadius: 4,
                                            spreadRadius: 1,
                                          ),
                                        ]
                                      : null,
                                ),
                              ),
                              const SizedBox(width: 4),
                              Text(
                                syncSettings.is2WayLiveSyncActive
                                    ? 'SYNCED'
                                    : 'OFFLINE',
                                style: TextStyle(
                                  color: syncSettings.is2WayLiveSyncActive
                                      ? customColors.primaryAccent
                                      : customColors.textMuted,
                                  fontWeight: FontWeight.w800,
                                  fontSize: 9,
                                  letterSpacing: 0.5,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  // Ambient Room Radar: Now Capsule
                  if (heroClass.courseCode.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 3),
                      decoration: BoxDecoration(
                        color: customColors.academic.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: customColors.academic.withValues(alpha: 0.15),
                          width: 1,
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: customColors.academic,
                              boxShadow: [
                                BoxShadow(
                                  color: customColors.academic
                                      .withValues(alpha: 0.5),
                                  blurRadius: 4,
                                  spreadRadius: 1,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            heroClass.startsIn.isNotEmpty
                                ? heroClass.startsIn
                                : 'Up next',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: customColors.academic,
                              fontWeight: FontWeight.w700,
                              fontSize: 10,
                            ),
                          ),
                          const SizedBox(width: 6),
                          Text(
                            '${heroClass.courseCode} • ${heroClass.location}',
                            style: theme.textTheme.labelSmall?.copyWith(
                              color: customColors.textSecondary,
                              fontWeight: FontWeight.w600,
                              fontSize: 10,
                            ),
                          ),
                        ],
                      ),
                    )
                  else
                    Text(
                      subtitle,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: theme.textTheme.labelMedium?.copyWith(
                        color: customColors.textSecondary,
                        fontWeight: FontWeight.w600,
                        fontSize: 12,
                      ),
                    ),
                ],
              ),
            ),

            // Theme toggle button
            IconButton(
              tooltip: isDark ? 'Switch to Light Mode' : 'Switch to Dark Mode',
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: const EdgeInsets.all(6),
              icon: Icon(
                isDark ? Icons.light_mode_rounded : Icons.dark_mode_rounded,
                size: 20,
                color: customColors.textSecondary,
              ),
              onPressed: () {
                ref.read(themeModeProvider.notifier).state =
                    isDark ? ThemeMode.light : ThemeMode.dark;
              },
            ),

            // Defense Controls & Settings
            IconButton(
              tooltip: 'Defense Controls & Settings',
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: const EdgeInsets.all(6),
              icon: Icon(
                Icons.shield_moon_rounded,
                size: 20,
                color: customColors.textSecondary,
              ),
              onPressed: () {
                SettingsSheet.show(context);
              },
            ),

            // Gemini AI BYOK Settings button
            IconButton(
              tooltip: hasApiKey
                  ? 'Gemini AI: Active (Tap to view/change)'
                  : 'Gemini AI: No Key (Tap to configure)',
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: const EdgeInsets.all(6),
              icon: Stack(
                clipBehavior: Clip.none,
                children: [
                  Icon(
                    hasApiKey ? Icons.auto_awesome : Icons.auto_awesome_outlined,
                    size: 20,
                    color: hasApiKey
                        ? customColors.primaryAccent
                        : customColors.textSecondary,
                  ),
                  Positioned(
                    right: -2,
                    top: -2,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: hasApiKey
                            ? customColors.success
                            : customColors.warning,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: theme.scaffoldBackgroundColor,
                          width: 1.5,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              onPressed: () => ApiSettingsDialog.show(context),
            ),

            // Notification button
            IconButton(
              tooltip: 'Notifications',
              constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
              padding: const EdgeInsets.all(6),
              icon: Icon(
                Icons.notifications_outlined,
                size: 22,
                color: customColors.textSecondary,
              ),
              onPressed: onNotificationTap ??
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                            'Shield Alerts: All 4 boundaries armed & unbreached.'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: customColors.cardBackground,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                          side: BorderSide(color: customColors.cardBorder),
                        ),
                      ),
                    );
                  },
            ),

            // Profile Avatar
            GestureDetector(
              onTap: onProfileTap ??
                  () {
                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: const Text(
                            'Alex Vance • CSE Major • Semester 4 (Week 7)'),
                        behavior: SnackBarBehavior.floating,
                        backgroundColor: customColors.cardBackground,
                      ),
                    );
                  },
              child: Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: customColors.primaryAccent.withValues(alpha: 0.4),
                    width: 1.5,
                  ),
                ),
                child: ClipOval(
                  child: Container(
                    color: customColors.primaryAccent.withValues(alpha: 0.15),
                    child: Icon(
                      Icons.person,
                      size: 20,
                      color: customColors.primaryAccent,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
