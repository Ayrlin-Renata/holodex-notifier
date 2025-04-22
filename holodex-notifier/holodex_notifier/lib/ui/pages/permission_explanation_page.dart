import 'package:flutter/material.dart';
import 'package:holodex_notifier/main.dart';
import 'package:holodex_notifier/ui/screens/home_screen.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'dart:io' show Platform;

class PermissionExplanationPage extends HookConsumerWidget {
  const PermissionExplanationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final notificationService = ref.watch(notificationServiceProvider);
    final logger = ref.watch(loggingServiceProvider);
    final theme = Theme.of(context);
    final permissionsGranted = useState(false);
    final batteryState = useState<AsyncValue<bool>>(const AsyncValue.loading());
    final isLoading = useState(false);
    final needsNavigation = useState(false);
    final appLifecycleState = useAppLifecycleState();

    final checkBatteryStatus = useCallback(() async {
      logger.info("[Permission Page CheckBatt] ENTERING checkBatteryStatus");

      if (!Platform.isAndroid) {
        logger.info("[Permission Page CheckBatt] Not Android, setting state to true.");
        if (batteryState.value is! AsyncData || !(batteryState.value as AsyncData).value) {
          batteryState.value = const AsyncValue.data(true);
        }
        return;
      }

      logger.trace("[Permission Page CheckBatt] Proceeding with actual check...");
      try {
        final isDisabled = await notificationService.isBatteryOptimizationDisabled();

        logger.info("[Permission Page CheckBatt] Check COMPLETE. Result: isDisabled = $isDisabled");

        if (batteryState.value.asData?.value != isDisabled) {
          logger.info("[Permission Page CheckBatt] Updating state to AsyncValue.data($isDisabled)");
          batteryState.value = AsyncValue.data(isDisabled);
        } else {
          logger.trace("[Permission Page CheckBatt] State already reflects isDisabled = $isDisabled. No update.");
        }
      } catch (e, s) {
        logger.error("[Permission Page CheckBatt] Check FAILED", e, s);

        batteryState.value = AsyncValue.error(e, s);
      }

      logger.info("[Permission Page CheckBatt] EXITING checkBatteryStatus");
    }, [notificationService, logger, batteryState]);

    useEffect(() {
      logger.info("[Permission Page Effect Initial] Running initial check effect.");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        logger.info("[Permission Page Effect Initial] Post frame callback: Calling checkBatteryStatus.");
        checkBatteryStatus();
      });
      return null;
    }, [checkBatteryStatus]);

    useEffect(() {
      logger.trace(
        "[Permission Page Effect Lifecycle] State changed to: $appLifecycleState.",
      );
      if (appLifecycleState == AppLifecycleState.resumed) {
        logger.info("[Permission Page Effect Lifecycle] App resumed. Calling checkBatteryStatus.");
        checkBatteryStatus();
      }
      return null;
    }, [appLifecycleState, checkBatteryStatus]);

    useEffect(() {
      final bool isBattDisabled = batteryState.value.maybeWhen(data: (d) => d, orElse: () => false);
      final bool nonAndroid = !Platform.isAndroid;
      final bool navCondition = permissionsGranted.value && (isBattDisabled || nonAndroid);

      logger.trace(
        "[Permission Page Effect Nav Check] Evaluating navigation: corePerms=${permissionsGranted.value}, isBattDisabled=$isBattDisabled, nonAndroid=$nonAndroid ==> ConditionMet=$navCondition",
      );

      if (navCondition) {
        if (!needsNavigation.value) {
          logger.info("[Permission Page Effect Nav Check] Conditions met for navigation. Setting needsNavigation flag.");
          needsNavigation.value = true;
        }
      } else {
        if (needsNavigation.value) {
          logger.trace("[Permission Page Effect Nav Check] Conditions no longer met. Resetting needsNavigation flag.");
          needsNavigation.value = false;
        }
      }
      return null;
    }, [permissionsGranted.value, batteryState.value]);

    useEffect(() {
      if (needsNavigation.value) {
        logger.info("[Permission Page Effect Perform Nav] needsNavigation=true. Scheduling navigation.");
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (context.mounted) {
            logger.info("[Permission Page Effect Perform Nav] Post Frame: Widget mounted, navigating now.");
            Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const HomeScreen()));
          } else {
            logger.warning("[Permission Page Effect Perform Nav] Post Frame: Widget unmounted before navigation could occur.");
          }
        });
      }
      return null;
    }, [needsNavigation.value]);

    return Scaffold(
      appBar: AppBar(title: const Text('Permissions Required'), automaticallyImplyLeading: false),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('Hand \'em over.', style: theme.textTheme.headlineSmall),
            const SizedBox(height: 16),
            _PermissionItem(
              icon: Icons.notifications_active_outlined,
              title: 'Notifications',
              description: '...to send you notifications for livestreams, new uploads, and scheduled reminders.',
            ),
            _PermissionItem(
              icon: Icons.schedule_outlined,
              title: 'Schedule Exact Alarm',
              description: 'Android 12+ requires this in order to send notifications at specific times, or else the notifications might be late.',
            ),
            if (Platform.isAndroid)
              _PermissionItem(
                icon: Icons.battery_alert_outlined,
                title: 'Disable Battery Optimization',
                description:
                    'Battery Optimization can stop the background process needed to retrieve the latest data. If that happens, the notifications will just randomly stop until you open the app again.\nYou can monitor the battery usage in your Settings.',
                trailing: batteryState.value.when(
                  data:
                      (isDisabled) =>
                          isDisabled
                              ? Icon(Icons.check_circle_outline, color: Colors.green[700], key: const ValueKey('batt_ok'))
                              : Icon(Icons.error_outline, color: Colors.orange[700], key: const ValueKey('batt_warn')),
                  loading:
                      () => const SizedBox(width: 20, height: 20, key: ValueKey('batt_loading'), child: CircularProgressIndicator(strokeWidth: 2)),
                  error: (err, stack) {
                    logger.error("[Permission Page Build BattItem] Error state in batteryState: $err");
                    return Icon(Icons.cancel_outlined, color: theme.colorScheme.error, key: const ValueKey('batt_error'));
                  },
                ),
              ),

            const Spacer(),
            ElevatedButton(
              onPressed:
                  (needsNavigation.value || isLoading.value)
                      ? null
                      : () async {
                        isLoading.value = true;
                        permissionsGranted.value = false;
                        logger.info("[Permission Page Button] Grant Permissions button pressed.");

                        final statuses = await notificationService.requestRequiredPermissions();
                        bool corePermsGranted = statuses[Permission.notification]?.isGranted ?? false;
                        if (Platform.isAndroid) {
                          corePermsGranted = corePermsGranted && (statuses[Permission.scheduleExactAlarm]?.isGranted ?? false);
                        }

                        if (!corePermsGranted) {
                          logger.warning("[Permission Page Button] Core permissions not granted. Statuses: $statuses");
                          if (context.mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Core permissions (Notification, Exact Alarm) are required.'),
                                duration: Duration(seconds: 4),
                              ),
                            );
                          }
                          isLoading.value = false;
                          return;
                        }

                        logger.info("[Permission Page Button] Core permissions granted.");
                        permissionsGranted.value = true;

                        if (Platform.isAndroid) {
                          final bool requiresRequest = batteryState.value.maybeWhen(
                            data: (isDisabled) => !isDisabled,
                            loading: () => true,
                            error: (_, __) => true,
                            orElse: () => true,
                          );

                          if (requiresRequest) {
                            logger.info(
                              "[Permission Page Button] Battery optimization needs to be disabled (Current State: ${batteryState.value}). Requesting user action...",
                            );
                            await notificationService.requestBatteryOptimizationDisabled();
                            logger.info("[Permission Page Button] System settings requested for battery optimization.");
                          } else {
                            logger.info("[Permission Page Button] Battery optimization already disabled or state reflects disabled. No request needed.");
                          }
                        } else {
                          logger.info("[Permission Page Button] Skipping battery optimization step (Not Android).");
                        }

                        isLoading.value = false;
                      },
              child:
                  isLoading.value
                      ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                      : (Platform.isAndroid && batteryState.value.maybeWhen(data: (d) => !d, orElse: () => true))
                      ? const Text('Grant Permissions & Disable Optimization')
                      : const Text('Grant Permissions'),
            ),

            const SizedBox(height: 16),
          ],
        ),
      ),
    );
  }
}

class _PermissionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Widget? trailing;

  const _PermissionItem({required this.icon, required this.title, required this.description, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.secondaryContainer.withValues(alpha: 0.3),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.onSecondaryContainer),
        title: Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer)),
        subtitle: Text(description, style: TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer.withValues(alpha: 0.8))),
        trailing: trailing,
      ),
    );
  }
}