import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:holodex_notifier/main.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';

class CreditsCard extends ConsumerWidget {
  const CreditsCard({super.key});

  Future<void> _launchUrl(BuildContext context, String urlString, WidgetRef ref) async {
    final logger = ref.watch(loggingServiceProvider);
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

  Widget _buildLinkTile(
    BuildContext context,
    WidgetRef ref, {
    required Widget icon,
    required String title,
    required String subtitle,
    required String url,
  }) {
    return ListTile(
      leading: SizedBox(width: 24, height: 24, child: Center(child: icon)),
      title: Text(title),
      subtitle: Text(subtitle),
      trailing: const Icon(Icons.open_in_new_rounded, size: 16),
      dense: true,
      onTap: () => _launchUrl(context, url, ref),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    const String kofiUserId = 'Z8Z13N1ZR';
    const String kofiUrl = 'https://ko-fi.com/$kofiUserId';
    const Color iconsColor = Color(0xFF0099AA);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const SizedBox(height: 16.0),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 0, vertical: 8.0),
          child: Text('Contact Information / Support', style: theme.textTheme.titleMedium?.copyWith(color: theme.colorScheme.secondary)),
        ),
        const SizedBox(height: 8.0),

        ListTile(
          leading: CircleAvatar(
            radius: 20,
            backgroundColor: theme.colorScheme.secondaryContainer,
            backgroundImage: const AssetImage('assets/images/ayrlin-pfp.png'),
          ),
          title: const Text('App Developer'),
          subtitle: const Text('ayrlin'),
          dense: true,
        ),

        _buildLinkTile(
          context,
          ref,
          icon: FaIcon(FontAwesomeIcons.bluesky, color: iconsColor, size: 20),
          title: 'Bluesky',
          subtitle: '@ayrl.in',
          url: 'https://bsky.app/profile/ayrl.in',
        ),
        _buildLinkTile(
          context,
          ref,
          icon: const FaIcon(FontAwesomeIcons.xTwitter, color: iconsColor, size: 20),
          title: 'Twitter / X',
          subtitle: '@ayrlinrenata',
          url: 'https://twitter.com/ayrlinrenata',
        ),
        _buildLinkTile(
          context,
          ref,
          icon: const Icon(Icons.email_outlined, color: iconsColor),
          title: 'Email',
          subtitle: 'ayrlin.renata@gmail.com',
          url: 'mailto:ayrlin.renata@gmail.com',
        ),

        _buildLinkTile(
          context,
          ref,
          icon: Icon(Icons.coffee_outlined, color: iconsColor),
          title: 'Ko-fi',
          subtitle: 'Buy me a coffee!',
          url: kofiUrl,
        ),

        const SizedBox(height: 16.0),
        Text('Without Holodex, none of this would be possible.', style: theme.textTheme.titleSmall?.copyWith(color: theme.colorScheme.secondary)),
        _buildLinkTile(
          context,
          ref,
          icon: const Icon(Icons.play_arrow_outlined),
          title: 'API Powered by',
          subtitle: 'Holodex.net',
          url: 'https://holodex.net',
        ),
      ],
    );
  }
}
