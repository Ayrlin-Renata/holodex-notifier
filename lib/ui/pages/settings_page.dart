import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:holodex_notifier/ui/widgets/app_behavior_settings_card.dart';
import 'package:holodex_notifier/ui/widgets/background_status_card.dart';
import 'package:holodex_notifier/ui/widgets/credits_card.dart';
import 'package:holodex_notifier/ui/widgets/logs_data_card.dart';

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return ListView(
      padding: const EdgeInsets.all(16.0),
      children: const [
        AppBehaviorSettingsCard(),
        SizedBox(height: 32),
        LogsDataCard(),
        SizedBox(height: 32),
        BackgroundStatusCard(),
        SizedBox(height: 32),
        CreditsCard(),
      ],
    );
  }
}
