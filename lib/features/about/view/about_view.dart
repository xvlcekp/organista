import 'package:flutter/material.dart';
import 'package:organista/l10n/app_localizations.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:flutter_hooks/flutter_hooks.dart';

class AboutView extends HookWidget {
  const AboutView({super.key});

  @override
  Widget build(BuildContext context) {
    final localizations = AppLocalizations.of(context);
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
            Text(
              '© 2025 Organista',
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
