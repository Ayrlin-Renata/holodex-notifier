import 'package:flutter/material.dart';
import 'package:holodex_notifier/main.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:holodex_notifier/ui/screens/home_screen.dart';

class PermissionExplanationPage extends HookConsumerWidget {
  const PermissionExplanationPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final localNotificationService = ref.read(notificationServiceProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Permissions Needed')),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text("Holodex Notifier needs permissions.", style: theme.textTheme.headlineMedium, textAlign: TextAlign.center),
            const SizedBox(height: 48.0),
            Text("Notification Permission", style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
            const SizedBox(height: 8.0),
            Text(
              "To send you notifications for live streams, new uploads, and scheduled reminders.",
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 16.0),
            Text("Precise Alarms & Reminders Permission", style: theme.textTheme.titleLarge, textAlign: TextAlign.center),
            Text(" (Android 12+)", style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
            const SizedBox(height: 8.0),
            Text(
              "On newer versions of Android, this permission is required to ensure timely reminders, which are essential for the app's core functionality.",
              style: theme.textTheme.bodyLarge,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32.0),
            ElevatedButton(
              onPressed: () async {
                final permissionsGranted = await localNotificationService.requestNotificationPermissions();
                if (permissionsGranted) {
                  if (context.mounted) {
                    Navigator.pushReplacement(context, MaterialPageRoute(builder: (context) => const HomeScreen()));
                  }
                } else {
                  if (context.mounted) {
                    ScaffoldMessenger.of(
                      context,
                    ).showSnackBar(const SnackBar(content: Text('Permissions not granted. Please enable them in settings.')));
                  }
                }
              },
              child: const Text('Continue'),
            ),
            const SizedBox(height: 8.0),
            Text("You can change these settings later in the app if needed.", style: theme.textTheme.bodyMedium, textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }
}
