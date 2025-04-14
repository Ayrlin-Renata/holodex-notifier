import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// Import the refactored card content widgets
import 'package:holodex_notifier/ui/widgets/app_behavior_settings_card.dart';
import 'package:holodex_notifier/ui/widgets/background_status_card.dart';
// {{ Import the new CreditsCard }}
import 'package:holodex_notifier/ui/widgets/credits_card.dart'; 

// This page displays general app settings and background status.
class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // This page doesn't need its own RefreshIndicator.

    return ListView(
      padding: const EdgeInsets.all(16.0), // Add default padding around the page content
      children: const [
        AppBehaviorSettingsCard(),
        SizedBox(height: 16),
        BackgroundStatusCard(),
         SizedBox(height: 16), // {{ Add spacing }}
         // {{ Add the CreditsCard }}
         CreditsCard(), 
         // Add other settings sections/cards here if needed in the future
      ],
    );
  }
}
