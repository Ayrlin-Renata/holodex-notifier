import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holodex_notifier/main.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart'; // {{ Import FontAwesome }}

class CreditsCard extends ConsumerWidget {
  const CreditsCard({super.key});

  // Helper function to launch URLs safely
  Future<void> _launchUrl(BuildContext context, String urlString, WidgetRef ref) async {
    // ... (launchUrl function remains the same) ...
    final logger = ref.watch(loggingServiceProvider); // Get logger
    final Uri url = Uri.parse(urlString);
    try {
      if (await canLaunchUrl(url)) {
        await launchUrl(url, mode: LaunchMode.externalApplication);
        logger.info("Launched URL: $urlString");
      } else {
        logger.warning("Could not launch URL: $urlString");
        if (context.mounted) {
          ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Could not open link: $urlString')));
        }
      }
    } catch (e, s) {
      logger.error("Error launching URL: $urlString", e, s);
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error opening link: $e')));
      }
    }
  }

  // Helper for creating social ListTiles
  Widget _buildLinkTile(
    BuildContext context,
    WidgetRef ref, { // Renamed for generality
    required Widget icon,
    required String title,
    required String subtitle,
    required String url,
  }) {
    return ListTile(
      // {{ Use the widget directly }}
      leading: SizedBox(width: 24, height: 24, child: Center(child: icon)), // Constrain icon size
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.open_in_new_rounded, size: 16), // Use rounded icon
      dense: true,
      onTap: () => _launchUrl(context, url, ref),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    // Ko-fi Details
    const String kofiUserId = 'Z8Z13N1ZR';
    const String kofiUrl = 'https://ko-fi.com/$kofiUserId';
    const Color iconsColor = Color(0xFF0099AA); // Defined Ko-fi brand color

    // Return the Column directly
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16.0),
        // {{ Use Padding instead of Card's internal padding }}
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8.0), // Adjusted padding
          child: Text(
            'Contact Information / Support',
            // Use a slightly less prominent style if needed
            style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.secondary),
          ),
        ),
        // {{ Use a simple SizedBox instead of Divider here }}
        const SizedBox(height: 8.0),

        // Developer Info
        ListTile(
          leading: CircleAvatar(
            radius: 20, // Adjust size as needed
            backgroundColor: theme.colorScheme.secondaryContainer, // Background if image fails
            backgroundImage: const AssetImage(
              'assets/images/ayrlin-pfp.png', // Path relative to pubspec.yaml
            ),
          ),
          title: const Text('App Developer'),
          subtitle: const Text('ayrlin'),
          dense: true,
        ),

        // Social Links
        _buildLinkTile(
          context,
          ref,
          // {{ Use FontAwesome Bluesky }}
          icon: FaIcon(FontAwesomeIcons.bluesky, color: iconsColor, size: 20),
          title: 'Bluesky',
          subtitle: '@ayrl.in',
          url: 'https://bsky.app/profile/ayrl.in',
        ),
        _buildLinkTile(
          context,
          ref,
          // {{ Use FontAwesome Twitter/X }}
          icon: const FaIcon(FontAwesomeIcons.xTwitter, color: iconsColor, size: 20),
          title: 'Twitter / X',
          subtitle: '@ayrlinrenata',
          url: 'https://twitter.com/ayrlinrenata',
        ),
        _buildLinkTile(
          context,
          ref,
          icon: const Icon(Icons.email_outlined, color: iconsColor), // Keep email icon
          title: 'Email',
          subtitle: 'ayrlin.renata@gmail.com',
          url: 'mailto:ayrlin.renata@gmail.com',
        ),

        // {{ Ko-fi Link as ListTile }}
        _buildLinkTile(
          context,
          ref,
          // {{ Use coffee icon, potentially FontAwesome }}
          icon: Icon(Icons.coffee_outlined, color: iconsColor), // Or FaIcon(FontAwesomeIcons.mugSaucer..)
          title: 'Ko-fi',
          subtitle: 'Buy me a coffee!',
          url: kofiUrl,
        ),

        const SizedBox(height: 16.0), // Spacing
        Text(
            'Without Holodex, none of this would be possible.',
            // Use a slightly less prominent style if needed
            style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.secondary),
          ),
        // API Credit
        _buildLinkTile(
          context,
          ref,
          // {{ Use Material Play icon }}
          icon: const Icon(Icons.play_arrow_outlined),
          title: 'API Powered by',
          subtitle: 'Holodex.net',
          url: 'https://holodex.net',
        ),
      ],
    );
  }
}
