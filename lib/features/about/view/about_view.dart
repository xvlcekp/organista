import 'package:flutter/material.dart';
import 'package:organista/config/app_constants.dart';
import 'package:organista/dialogs/error_dialog.dart';
import 'package:organista/extensions/buildcontext/loc.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:url_launcher/url_launcher.dart';

class AboutView extends HookWidget {
  const AboutView({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = context.loc;
    final version = useState<String>('');

    useEffect(() {
      PackageInfo.fromPlatform().then((packageInfo) {
        version.value = packageInfo.version;
      });
      return null;
    }, []);

    return Scaffold(
      appBar: AppBar(
        title: Text(localizations.about),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              localizations.aboutMessage,
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 24),
            InkWell(
              onTap: () async {
                final Uri url = Uri.parse(AppConstants.faqUrl);
                try {
                  if (await canLaunchUrl(url)) {
                    await launchUrl(url, mode: LaunchMode.externalApplication);
                  } else {
                    if (context.mounted) {
                      showErrorDialog(context, localizations.couldNotOpenUrl);
                    }
                  }
                } catch (e) {
                  if (context.mounted) {
                    showErrorDialog(context, '${localizations.errorOpeningUrl}: ${e.toString()}');
                  }
                }
              },
              child: Text(
                localizations.frequentlyAskedQuestions,
                style: Theme.of(
                  context,
                ).textTheme.headlineSmall?.copyWith(color: Theme.of(context).colorScheme.primary),
              ),
            ),
            const SizedBox(height: 20),
            SelectableText(
              'Email: ${AppConstants.contactEmail}',
              style: Theme.of(context).textTheme.bodyLarge,
            ),
            const SizedBox(height: 20),
            Text(
              '2025 Organista',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            const SizedBox(height: 8),
            Text(
              '${localizations.version} ${version.value}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
          ],
        ),
      ),
    );
  }
}
