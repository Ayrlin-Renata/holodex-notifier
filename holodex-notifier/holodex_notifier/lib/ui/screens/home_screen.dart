import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

// Import the page widgets (they will be created in the next steps)
import 'package:holodex_notifier/ui/pages/scheduled_page.dart';
import 'package:holodex_notifier/ui/pages/channels_page.dart';
import 'package:holodex_notifier/ui/pages/settings_page.dart';
import 'package:holodex_notifier/ui/pages/notification_format_page.dart';

// Main screen containing the BottomNavigationBar and page routing
class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageController = usePageController(); // {{ Use a PageController }}

    // State hook for the selected navigation index
    final selectedIndex = useState(0); // Default to the first page (Scheduled)

    // List of the page widgets
    final List<Widget> pages = [
      ScheduledPage(pageController: pageController), // Index 0
      const ChannelsPage(), // Index 1
      const SettingsPage(), // Index 2
      const NotificationFormatPage(), // Index 3 - New Page
    ];

    // List of page titles for the AppBar
    final List<String> pageTitles = ['Notification Schedule', 'Channel Management', 'Application Settings', 'Notification Formatting'];

    useEffect(() {
      void listener() {
        final page = pageController.page?.round() ?? 0;
        if (selectedIndex.value != page) {
          selectedIndex.value = page;
        }
      }

      pageController.addListener(listener);
      return () => pageController.removeListener(listener);
    }, [pageController]);

    return Scaffold(
      appBar: AppBar(
        // Set AppBar title based on the selected page
        title: Text(pageTitles[selectedIndex.value]),
        // Add other AppBar elements if needed (e.g., actions)
      ),
      // Display the widget corresponding to the current selectedIndex
      body: PageView(
        controller: pageController,
        children: pages,
        onPageChanged: (index) {
          selectedIndex.value = index;
        },
      ),
      // Define the bottom navigation bar
      bottomNavigationBar: BottomNavigationBar(
        // Make icons smaller when there are more items
        iconSize: 20,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        type: BottomNavigationBarType.fixed, // Ensure all labels are visible
        // Items in the navigation bar
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.notifications_active_outlined), activeIcon: Icon(Icons.notifications_active), label: 'Scheduled'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt_outlined), activeIcon: Icon(Icons.list_alt), label: 'Channels'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: 'Settings'),
          BottomNavigationBarItem(icon: Icon(Icons.edit_note_outlined), activeIcon: Icon(Icons.edit_note), label: 'Formats'),
        ],
        // The currently selected item index
        currentIndex: selectedIndex.value,
        // Theme customization (optional)
        // selectedItemColor: Theme.of(context).colorScheme.primary,
        // unselectedItemColor: Theme.of(context).colorScheme.onSurfaceVariant,
        // showUnselectedLabels: true, // Adjust as needed
        // Callback when an item is tapped
        onTap: (index) {
          selectedIndex.value = index; // Update the state hook
          pageController.animateToPage(
            index,
            duration: const Duration(milliseconds: 300), // Add animation
            curve: Curves.easeInOut,
          );
        },
      ),
    );
  }
}
