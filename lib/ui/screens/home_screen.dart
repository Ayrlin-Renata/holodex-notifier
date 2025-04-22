import 'package:flutter/material.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:hooks_riverpod/hooks_riverpod.dart';

import 'package:holodex_notifier/ui/pages/scheduled_page.dart';
import 'package:holodex_notifier/ui/pages/channels_page.dart';
import 'package:holodex_notifier/ui/pages/settings_page.dart';
import 'package:holodex_notifier/ui/pages/notification_format_page.dart';

class HomeScreen extends HookConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pageController = usePageController();

    final selectedIndex = useState(0);

    final List<Widget> pages = [ScheduledPage(pageController: pageController), ChannelsPage(), const SettingsPage(), const NotificationFormatPage()];

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
      appBar: AppBar(title: Text(pageTitles[selectedIndex.value])),
      body: PageView(
        controller: pageController,
        children: pages,
        onPageChanged: (index) {
          selectedIndex.value = index;
        },
      ),
      bottomNavigationBar: BottomNavigationBar(
        iconSize: 20,
        selectedFontSize: 12,
        unselectedFontSize: 12,
        type: BottomNavigationBarType.fixed,
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(icon: Icon(Icons.notifications_active_outlined), activeIcon: Icon(Icons.notifications_active), label: 'Scheduled'),
          BottomNavigationBarItem(icon: Icon(Icons.list_alt_outlined), activeIcon: Icon(Icons.list_alt), label: 'Channels'),
          BottomNavigationBarItem(icon: Icon(Icons.settings_outlined), activeIcon: Icon(Icons.settings), label: 'Settings'),
          BottomNavigationBarItem(icon: Icon(Icons.edit_note_outlined), activeIcon: Icon(Icons.edit_note), label: 'Formats'),
        ],
        currentIndex: selectedIndex.value,
        onTap: (index) {
          selectedIndex.value = index;
          pageController.animateToPage(index, duration: const Duration(milliseconds: 300), curve: Curves.easeInOut);
        },
      ),
    );
  }
}
