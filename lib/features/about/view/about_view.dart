import 'dart:async';

import 'package:flutter/material.dart';
import 'package:organista/config/app_constants.dart';
import 'package:organista/dialogs/error_dialog.dart';
import 'package:organista/extensions/buildcontext/localization.dart';
import 'package:in_app_review/in_app_review.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:share_plus/share_plus.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutView extends HookWidget {
  const AboutView({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = context.loc;
    final textTheme = Theme.of(context).textTheme;
    final version = useState<String>('');
    final currentYear = DateTime.now().year;
    final copyrightYears = currentYear > AppConstants.copyrightStartYear
        ? '${AppConstants.copyrightStartYear}–$currentYear'
        : '${AppConstants.copyrightStartYear}';

    useEffect(() {
      PackageInfo.fromPlatform().then((packageInfo) {
        version.value = packageInfo.version;
      });
      return null;
    }, []);

    Future<void> open(Uri url) async {
      try {
        await launchUrl(url, mode: LaunchMode.externalApplication);
      } catch (e) {
        if (context.mounted) {
          unawaited(showErrorDialog(context: context, text: '${localizations.errorOpeningUrl(url.toString())}: $e'));
        }
      }
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.about),
      ),
      body: ListView(
        children: [
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(localizations.aboutMessage, style: textTheme.bodyLarge),
          ),
          ListTile(
            leading: const Icon(Icons.menu_book),
            title: Text(localizations.userGuide),
            onTap: () => open(Uri.parse(AppConstants.userGuideUrl)),
          ),
          ListTile(
            leading: const Icon(Icons.help_outline),
            title: Text(localizations.frequentlyAskedQuestions),
            onTap: () => open(Uri.parse(AppConstants.faqUrl)),
          ),
          ListTile(
            leading: const Icon(Icons.new_releases_outlined),
            title: Text(localizations.whatsNew),
            onTap: () => open(Uri.parse(AppConstants.whatsNewUrl)),
          ),
          ListTile(
            leading: const Icon(Icons.library_music_outlined),
            title: Text(localizations.musicSheetSources),
            onTap: () => open(Uri.parse(AppConstants.musicSheetSourcesUrl)),
          ),
          const Divider(),
          ListTile(
            leading: const Icon(Icons.star_outline),
            title: Text(localizations.rateApp),
            onTap: () => InAppReview.instance.openStoreListing(appStoreId: AppConstants.appStoreId),
          ),
          ListTile(
            leading: const Icon(Icons.share_outlined),
            title: Text(localizations.shareApp),
            onTap: () => SharePlus.instance.share(
              ShareParams(text: localizations.shareAppText(AppConstants.playStoreUrl, AppConstants.appStoreUrl)),
            ),
          ),
          ListTile(
            leading: const Icon(Icons.email_outlined),
            title: const Text(AppConstants.contactEmail),
            onTap: () => open(Uri(scheme: 'mailto', path: AppConstants.contactEmail)),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Text(
              '$copyrightYears Organista\n${localizations.version} ${version.value}',
              style: textTheme.bodyMedium,
            ),
          ),
        ],
      ),
    );
  }
}
