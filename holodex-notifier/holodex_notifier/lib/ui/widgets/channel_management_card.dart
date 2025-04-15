import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';
import 'package:holodex_notifier/application/state/channel_providers.dart';
import 'package:holodex_notifier/application/state/settings_providers.dart';
import 'package:holodex_notifier/main.dart'; // For appControllerProvider
import 'package:holodex_notifier/ui/widgets/channel_settings_tile.dart';
// import 'package:holodex_notifier/ui/widgets/settings_card.dart'; // Remove SettingsCard import

class ChannelManagementCard extends HookConsumerWidget {
  const ChannelManagementCard({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);

    // State for channel search input
    final searchQueryController = useTextEditingController();

    // Watch Riverpod providers for search state and results
    final searchQuery = ref.watch(channelSearchQueryProvider);
    final asyncSearchResults = ref.watch(debouncedChannelSearchProvider);

    // Watch channel list
    final channelList = ref.watch(channelListProvider);
    final channelListNotifier = ref.watch(channelListProvider.notifier);

    // Watch global defaults
    final globalNew = ref.watch(globalNewMediaDefaultProvider);
    final globalMention = ref.watch(globalMentionsDefaultProvider);
    final globalLive = ref.watch(globalLiveDefaultProvider);
    final globalUpdate = ref.watch(globalUpdateDefaultProvider);
    final globalMembers = ref.watch(globalMembersOnlyDefaultProvider);
    final globalClips = ref.watch(globalClipsDefaultProvider);

    // Access AppController needed for add/remove actions
    final appController = ref.watch(appControllerProvider);

    // Update text controller if riverpod state changes externally (less likely now)
    useEffect(() {
      if (searchQueryController.text != searchQuery) {
        searchQueryController.text = searchQuery;
        // Move cursor to end
        searchQueryController.selection = TextSelection.fromPosition(TextPosition(offset: searchQueryController.text.length));
      }
      return null;
    }, [searchQuery]);

    // REMOVED: SettingsCard wrapper
    // Return the Column containing the card content directly
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start, // Align content to start
      children: [
        // --- Global Switches ---
        Text('Notification Type Defaults', style: theme.textTheme.labelLarge),
        Wrap(
          spacing: 8.0,
          children: [
            FilterChip(label: const Text('New'), selected: globalNew, onSelected: (v) => ref.read(globalNewMediaDefaultProvider.notifier).state = v),
            FilterChip(
              label: const Text('Mentions'),
              selected: globalMention,
              onSelected: (v) => ref.read(globalMentionsDefaultProvider.notifier).state = v,
            ),
            FilterChip(label: const Text('Live'), selected: globalLive, onSelected: (v) => ref.read(globalLiveDefaultProvider.notifier).state = v),
            FilterChip(
              label: const Text('Updates'),
              selected: globalUpdate,
              onSelected: (v) => ref.read(globalUpdateDefaultProvider.notifier).state = v,
            ),
            FilterChip(
              label: const Text('Members'),
              selected: globalMembers,
              onSelected: (v) => ref.read(globalMembersOnlyDefaultProvider.notifier).state = v,
            ),
            FilterChip(label: const Text('Clips'), selected: globalClips, onSelected: (v) => ref.read(globalClipsDefaultProvider.notifier).state = v),
          ],
        ),
        Center(
          child: ElevatedButton.icon(
            icon: const Icon(Icons.sync_outlined),
            label: const Text('Apply Defaults to All'),
            onPressed: () {
              // Use AppController method
              appController.applyGlobalDefaultsToAllChannels();
              ScaffoldMessenger.of(
                context,
              ).showSnackBar(const SnackBar(content: Text('Notification defaults applied to all channels'), duration: Duration(seconds: 2)));
            },
          ),
        ),
        const Divider(height: 24.0),

        // --- Channel Search ---
        TextField(
          controller: searchQueryController,
          decoration: InputDecoration(
            labelText: 'Search for channels to add',
            hintText: 'Enter channel name',
            prefixIcon: const Icon(Icons.search),
            suffixIcon:
                asyncSearchResults
                        .isLoading // Check loading state from FutureProvider
                    ? const Padding(
                      padding: EdgeInsets.all(12.0),
                      child: SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)),
                    )
                    : (searchQueryController.text.isNotEmpty
                        ? IconButton(
                          icon: const Icon(Icons.clear),
                          onPressed: () {
                            // Clear the riverpod state, which clears the text field via useEffect
                            ref.read(channelSearchQueryProvider.notifier).state = '';
                          },
                        )
                        : null),
          ),
          // Update the Riverpod provider on change
          onChanged: (value) => ref.read(channelSearchQueryProvider.notifier).state = value,
        ),
        // --- Search Results ---
        // Use AsyncValue widget builder for cleaner loading/error handling
        asyncSearchResults.when(
          data: (currentResults) {
            if (currentResults.isEmpty) {
              // Show 'No results' only if query is long enough & not loading
              if (searchQuery.length >= 3) {
                return const Padding(padding: EdgeInsets.all(8.0), child: Center(child: Text('No channels found.')));
              } else {
                return const SizedBox.shrink(); // Nothing to show if query too short
              }
            }

            // Display results list
            return SizedBox(
              // Limit height of results box
              height: 200, // Adjust as needed
              child: ListView.builder(
                shrinkWrap: true,
                itemCount: currentResults.length,
                itemBuilder: (context, index) {
                  final channel = currentResults[index];
                  final bool alreadyAdded = channelList.any((c) => c.channelId == channel.id);

                  return ListTile(
                    title: Text(channel.name),
                    subtitle: Text(channel.englishName ?? channel.id, style: theme.textTheme.bodySmall),
                    trailing:
                        alreadyAdded
                            ? const Icon(Icons.check_circle, color: Colors.grey, semanticLabel: 'Already Added')
                            : IconButton(
                              icon: const Icon(Icons.add_circle_outline, color: Colors.green),
                              tooltip: 'Add Channel',
                              onPressed: () {
                                // Use AppController method
                                appController.addChannel(channel);
                                ScaffoldMessenger.of(
                                  context,
                                ).showSnackBar(SnackBar(content: Text('Added ${channel.name}'), duration: Duration(seconds: 2)));
                                // Clear search by clearing provider state
                                ref.read(channelSearchQueryProvider.notifier).state = '';
                              },
                            ),
                  );
                },
              ),
            );
          },
          error: (error, stackTrace) {
            String errorMessage;
            // --- ADD: Specific check for our custom exception ---
            if (error is ApiKeyRequiredException) {
              errorMessage = error.message; // Use the specific message
            } else {
              // --- END ADD ---
              errorMessage = 'Search failed. Please try again.'; // Generic fallback
              // Log the actual error for debugging
              print("Channel Search Error: $error\n$stackTrace");
            }
            return Padding(
              padding: const EdgeInsets.all(8.0),
              child: Center(
                child: Text(
                  errorMessage, // Display specific or generic message
                  style: TextStyle(color: theme.colorScheme.error),
                  textAlign: TextAlign.center,
                ),
              ),
            );
          },
          // Keep loading spinner centered
          loading: () => const Padding(padding: EdgeInsets.symmetric(vertical: 20.0), child: Center(child: CircularProgressIndicator())),
        ),

        const Divider(height: 24.0),
        Text('Added Channels (${channelList.length})', style: theme.textTheme.titleMedium),

        // --- Channel List ---
        if (channelList.isEmpty)
          const Center(child: Padding(padding: EdgeInsets.all(16.0), child: Text('No channels added yet. Use the search bar above to add channels.')))
        else
          // --- Ensure the key is ValueKey for ReorderableListView ---
          ReorderableListView.builder(
            key: ValueKey('reorderable_channel_list_${channelList.length}'),
            shrinkWrap: true,
            // Disable internal scrolling for this list. The parent page will handle overall scrolling.
            physics: const NeverScrollableScrollPhysics(),
            itemCount: channelList.length,
            itemBuilder: (context, index) {
              final channelSetting = channelList[index];
              return ChannelSettingsTile(
                key: ValueKey(channelSetting.channelId), // Key required for reorderable items
                channelSetting: channelSetting,
              );
            },
            onReorder: (int oldIndex, int newIndex) {
              channelListNotifier.reorderChannels(oldIndex, newIndex);
            },
          ),
      ],
    );
  }
}
