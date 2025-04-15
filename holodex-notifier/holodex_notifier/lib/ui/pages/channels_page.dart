import 'package:flutter/material.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:holodex_notifier/application/state/channel_providers.dart'; // Import channelListProvider
import 'package:holodex_notifier/main.dart'; // Import loggingServiceProvider
import 'package:holodex_notifier/ui/widgets/channel_management_card.dart'; // Import the refactored card content
import 'package:flutter_background_service/flutter_background_service.dart'; // {{ Import background service }}
// For background status

// This page displays channel management features and supports pull-to-refresh.
class ChannelsPage extends ConsumerWidget {
  const ChannelsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final logger = ref.watch(loggingServiceProvider);
    final bgService = FlutterBackgroundService(); // {{ Get service instance }}
    final scaffoldMessenger = ScaffoldMessenger.of(context); // {{ Get ScaffoldMessenger }}

    return RefreshIndicator(
      // Define the refresh action
      onRefresh: () async {
        logger.info("ChannelsPage: Pull-to-refresh triggered.");
        // Trigger the provider to reload its state from storage
        final channelRefreshFuture = ref.read(channelListProvider.notifier).reloadState();

        // Check if service is running before invoking
        final isRunning = await bgService.isRunning(); // Check status directly
        if (isRunning) {
          logger.info("ChannelsPage: Invoking manual poll from refresh...");
          bgService.invoke('triggerPoll');
          // Show feedback immediately
          scaffoldMessenger.showSnackBar(const SnackBar(content: Text('Manual poll triggered...'), duration: Duration(seconds: 2)));
        } else {
          logger.warning("ChannelsPage: Background service not running, manual poll not triggered from refresh.");
        }

        // Await the original refresh future
        await channelRefreshFuture;
        logger.info("ChannelsPage: Refresh action completed.");
      },
      // The content of the page
      child: ListView(padding: const EdgeInsets.all(16.0), children: const [ChannelManagementCard()]),
    );
  }
}
