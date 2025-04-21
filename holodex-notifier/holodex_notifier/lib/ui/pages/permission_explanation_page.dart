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
    // --- Existing Hooks ---
    final notificationService = ref.watch(notificationServiceProvider);
    final logger = ref.watch(loggingServiceProvider);
    final theme = Theme.of(context);
    final permissionsGranted = useState(false);
    final batteryState = useState<AsyncValue<bool>>(const AsyncValue.loading());
    final isLoading = useState(false);
    final needsNavigation = useState(false);
    final requestedBatterySettings = useState(false);
    final appLifecycleState = useAppLifecycleState();

    // --- Async Function Check Battery Status ---
    final checkBatteryStatus = useCallback(() async { // Removed context argument for now
       // **** ADDED LOG ****
      logger.info("[Permission Page CheckBatt] ENTERING checkBatteryStatus");
      // Avoid checking if not Android or if already loading
      if (!Platform.isAndroid) {
        logger.info("[Permission Page CheckBatt] Not Android, setting state to true.");
        if (batteryState.value is! AsyncData || !(batteryState.value as AsyncData).value) {
           batteryState.value = const AsyncValue.data(true);
        }
        return;
      }
      // Only set loading if not already loading to avoid flicker/redundant states
      // if (batteryState.value is! AsyncLoading) {
      //    logger.trace("[Permission Page CheckBatt] Setting state to LOADING");
      //    batteryState.value = const AsyncValue.loading();
      // }

      // **** ADDED LOG ****
      logger.trace("[Permission Page CheckBatt] Proceeding with actual check...");
      try {
        final isDisabled = await notificationService.isBatteryOptimizationDisabled();
        // **** ADDED LOG ****
        logger.info("[Permission Page CheckBatt] Check COMPLETE. Result: isDisabled = $isDisabled");
        // Only update state if the value is different to avoid unnecessary rebuilds
        if (batteryState.value.asData?.value != isDisabled) {
            // **** ADDED LOG ****
            logger.info("[Permission Page CheckBatt] Updating state to AsyncValue.data($isDisabled)");
            batteryState.value = AsyncValue.data(isDisabled);
        } else {
             logger.trace("[Permission Page CheckBatt] State already reflects isDisabled = $isDisabled. No update.");
        }
      } catch (e, s) {
        // **** ADDED LOG ****
        logger.error("[Permission Page CheckBatt] Check FAILED", e, s);
        // Only update state if it's not already an error? Or maybe always update?
        batteryState.value = AsyncValue.error(e, s);
        // Consider showing snackbar here if context is available or passed differently
      }
      // **** ADDED LOG ****
       logger.info("[Permission Page CheckBatt] EXITING checkBatteryStatus");
    }, [notificationService, logger, batteryState]); // Added batteryState to dependencies? Maybe not needed if using .value


    // --- Effect Hook for Initial Check ---
    useEffect(() {
      logger.info("[Permission Page Effect Initial] Running initial check effect.");
      WidgetsBinding.instance.addPostFrameCallback((_) {
        logger.info("[Permission Page Effect Initial] Post frame callback: Calling checkBatteryStatus.");
        checkBatteryStatus(); // Call without context
      });
      return null;
    }, [checkBatteryStatus]); // Keep dependency


    // --- Effect Hook for Lifecycle Changes ---
    useEffect(() {
      logger.trace("[Permission Page Effect Lifecycle] State changed to: $appLifecycleState. requestedBatterySettings=${requestedBatterySettings.value}");
      if (appLifecycleState == AppLifecycleState.resumed && requestedBatterySettings.value) {
        logger.info("[Permission Page Effect Lifecycle] App resumed after requesting settings. Calling checkBatteryStatus.");
        requestedBatterySettings.value = false;
        checkBatteryStatus(); // Call without context
      }
      return null;
    }, [appLifecycleState, requestedBatterySettings, checkBatteryStatus]); // Keep dependencies


    // --- Effect Hook for Navigation ---
    useEffect(() {
      final bool isBattDisabled = batteryState.value.maybeWhen(
          data: (d) => d,
          orElse: () => false // Default to false if loading or error
      );
      final bool nonAndroid = !Platform.isAndroid;
      final bool navCondition = permissionsGranted.value && (isBattDisabled || nonAndroid);

      // **** ADDED LOG ****
      logger.trace("[Permission Page Effect Nav Check] Evaluating navigation: corePerms=${permissionsGranted.value}, isBattDisabled=$isBattDisabled, nonAndroid=$nonAndroid ==> ConditionMet=$navCondition");

      if (navCondition) {
        if (!needsNavigation.value) { // Only set if not already set
           logger.info("[Permission Page Effect Nav Check] Conditions met for navigation. Setting needsNavigation flag.");
           needsNavigation.value = true;
        }
      } else {
         if (needsNavigation.value) { // Only reset if currently true
            logger.trace("[Permission Page Effect Nav Check] Conditions no longer met. Resetting needsNavigation flag.");
            needsNavigation.value = false;
         }
      }
      return null;
    }, [permissionsGranted.value, batteryState.value]);


    // --- Effect Hook to Perform Navigation ---
    useEffect(() {
      if (needsNavigation.value) {
        logger.info("[Permission Page Effect Perform Nav] needsNavigation=true. Scheduling navigation.");
        WidgetsBinding.instance.addPostFrameCallback((_) {
          // Check mount status again just before navigating
          if (context.mounted) {
             logger.info("[Permission Page Effect Perform Nav] Post Frame: Widget mounted, navigating now.");
             Navigator.of(context).pushReplacement(
                MaterialPageRoute(builder: (context) => const HomeScreen()),
             );
             // It's okay to set needsNavigation back here or not, as pushReplacement removes this page
             // needsNavigation.value = false;
          } else {
             logger.warning("[Permission Page Effect Perform Nav] Post Frame: Widget unmounted before navigation could occur.");
          }
        });
      }
      return null;
    }, [needsNavigation.value]);


    // --- Build Method ---
    return Scaffold(
      // ... AppBar ...
       appBar: AppBar(
         title: const Text('Permissions Required'),
         automaticallyImplyLeading: false,
       ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // ... Explanation Text and Permission Items ...
            Text(
              'Why These Permissions?',
              style: theme.textTheme.headlineSmall,
            ),
            const SizedBox(height: 16),
            _PermissionItem(
              icon: Icons.notifications_active_outlined,
              title: 'Notifications',
              description: 'Required to show alerts when followed streams are about to start or go live.',
            ),
            _PermissionItem(
              icon: Icons.schedule_outlined,
              title: 'Schedule Exact Alarm (Android)',
              description: 'Needed to schedule notifications precisely, ensuring reminders appear at the correct time before a stream starts.',
            ),
            if (Platform.isAndroid)
              _PermissionItem(
                icon: Icons.battery_alert_outlined,
                title: 'Disable Battery Optimization',
                description: 'Android can stop background tasks to save power. Disabling optimization for this app ensures reliable stream checking and timely notifications.',
                trailing: batteryState.value.when(
                  data: (isDisabled) => isDisabled
                      ? Icon(Icons.check_circle_outline, color: Colors.green[700], key: const ValueKey('batt_ok'))
                      : Icon(Icons.error_outline, color: Colors.orange[700], key: const ValueKey('batt_warn')),
                  loading: () => const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2), key: ValueKey('batt_loading')),
                  error: (err, stack) {
                     // **** ADDED LOG ****
                     logger.error("[Permission Page Build BattItem] Error state in batteryState: $err");
                     return Icon(Icons.cancel_outlined, color: theme.colorScheme.error, key: const ValueKey('batt_error'));
                  },
                ),
              ),

            // --- Conditional Warning Message ---
            // Use maybeWhen for conciseness if only checking data state
            //  if (Platform.isAndroid && batteryState.value.maybeWhen(data: (d) => !d, orElse: () => false))
            //      Padding(
            //           // ... Warning Card unchanged ...
            //          padding: const EdgeInsets.symmetric(vertical: 8.0),
            //          child: Card(
            //              color: theme.colorScheme.errorContainer, // Provide fallback color
            //              elevation: 0,
            //              child: Padding(
            //                 padding: const EdgeInsets.all(8.0),
            //                 child: Text(
            //                     'Warning: Battery optimization is still active. Background checks and notifications might be unreliable or delayed. Please grant permission when prompted, or disable it manually in system settings.',
            //                     style: TextStyle(color: theme.colorScheme.onErrorContainer) , // Provide fallback color
            //                 ),
            //              ),
            //          ),
            //      ),

            // ... Spacer and Button ...
            const Spacer(),
            ElevatedButton(
              onPressed: (needsNavigation.value || isLoading.value)
                  ? null
                  : () async {
                       // ... Button logic largely unchanged, ensure logging exists ...
                        isLoading.value = true;
                        permissionsGranted.value = false;
                        logger.info("[Permission Page Button] Grant Permissions button pressed.");

                        // 1. Request Core Permissions
                         // ... (request logic as before) ...
                        final statuses = await notificationService.requestRequiredPermissions();
                        bool corePermsGranted = statuses[Permission.notification]?.isGranted ?? false;
                        if (Platform.isAndroid) {
                            corePermsGranted = corePermsGranted && (statuses[Permission.scheduleExactAlarm]?.isGranted ?? false);
                        }

                        if (!corePermsGranted) {
                            logger.warning("[Permission Page Button] Core permissions not granted. Statuses: $statuses");
                            if (context.mounted) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Core permissions (Notification, Exact Alarm) are required.'), duration: Duration(seconds: 4)),
                                );
                            }
                            isLoading.value = false;
                            return;
                        }

                        logger.info("[Permission Page Button] Core permissions granted.");
                        permissionsGranted.value = true;

                        // 2. Handle Battery Optimization
                        if (Platform.isAndroid) {
                            // Re-check state value *before* deciding to request
                            final bool requiresRequest = batteryState.value.maybeWhen(
                                data: (isDisabled) => !isDisabled, // Request if data shows it's NOT disabled
                                loading: () => true, // Assume request needed if loading? Risky maybe, let user trigger again
                                error: (_,s) => true, // Request if error state?
                                orElse: () => true // Default to requesting if state is weird
                            );

                            if (requiresRequest) {
                                logger.info("[Permission Page Button] Battery opt requires request (State: ${batteryState.value}). Requesting user action...");
                                requestedBatterySettings.value = true;
                                await notificationService.requestBatteryOptimizationDisabled();
                                logger.info("[Permission Page Button] Directed user to battery settings/prompt. Waiting for resume.");
                            } else {
                                logger.info("[Permission Page Button] Battery optimization already disabled or state is data(true). No request needed.");
                            }
                        } else {
                            logger.info("[Permission Page Button] Skipping battery optimization step (Not Android).");
                        }

                         isLoading.value = false; // Ensure loading state is reset
                  },
              child: isLoading.value
                  ? const SizedBox(height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 3, color: Colors.white))
                   // Check battery state more robustly for button text
                  : (Platform.isAndroid && batteryState.value.maybeWhen(data: (d) => !d, orElse: () => true)) // Show if not disabled or not loaded/error
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
// ... _PermissionItem unchanged below ...
class _PermissionItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Widget? trailing;

  const _PermissionItem({
    required this.icon,
    required this.title,
    required this.description,
    this.trailing,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3),
      margin: const EdgeInsets.symmetric(vertical: 6),
      child: ListTile(
        leading: Icon(icon, color: Theme.of(context).colorScheme.onSecondaryContainer),
        title: Text(title, style: TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer)),
        subtitle: Text(description, style: TextStyle(color: Theme.of(context).colorScheme.onSecondaryContainer.withOpacity(0.8))),
        trailing: trailing,
      ),
    );
  }
}