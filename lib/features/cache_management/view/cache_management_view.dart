import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:organista/config/app_constants.dart';
import 'package:organista/dialogs/generic_dialog.dart';
import 'package:organista/extensions/buildcontext/localization.dart';
import 'package:organista/features/cache_management/cubit/cache_cubit.dart';
import 'package:organista/features/cache_management/cubit/cache_state.dart';

/// Cache management screen (internal implementation)
///
/// Displays cache statistics and provides controls to manage cache:
/// - View number of cached files
/// - View total cache size
/// - Clear all cached files
class CacheManagementView extends StatelessWidget {
  const CacheManagementView({super.key});

  static const int _decimalPlaces = 2;
  static const double _iconSize = 32.0;

  Widget _buildCacheInfoTile({
    required IconData icon,
    required String title,
    required bool isLoading,
    required ThemeData theme,
    String? value,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: Icon(icon, size: _iconSize),
      title: Text(title, style: theme.textTheme.bodyMedium),
      trailing: isLoading
        ? const CircularProgressIndicator()
        : value != null
            ? Text(value, style: theme.textTheme.bodyMedium?.copyWith(fontWeight: FontWeight.bold))
            : null,
    );
  }

  Future<void> _showClearCacheDialog(BuildContext context, CacheLoaded cacheState) async {
    final localizations = context.loc;

    final confirmed = await showGenericDialog<bool>(
      context: context,
      title: '${localizations.clearCacheConfirmTitle}?',
      content: localizations.clearCacheConfirmMessage(
        cacheState.totalFiles,
        cacheState.sizeInMB.toStringAsFixed(_decimalPlaces),
      ),
      optionsBuilder: () => {
        localizations.cancel: false,
        localizations.clearCache: true,
      },
    );

    if (confirmed == true && context.mounted) {
      context.read<CacheCubit>().clearCache();
    }
  }

  @override
  Widget build(BuildContext context) {
    final localizations = context.loc;
    final theme = Theme.of(context);
    final titleMedium = theme.textTheme.titleMedium;


    return BlocListener<CacheCubit, CacheState>(
      listener: (context, cacheState) {
        // Show success message when cache is cleared
        if (cacheState is CacheCleared) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(localizations.cacheClearedSuccess),
              backgroundColor: Colors.green,
              duration: const Duration(seconds: 2),
            ),
          );
        }
        // Show error message if cache operation fails
        else if (cacheState is CacheError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('${localizations.error}: ${cacheState.message}'),
              backgroundColor: Colors.red,
              duration: const Duration(seconds: 3),
            ),
          );
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(localizations.storageManagement),
        ),
        body: BlocBuilder<CacheCubit, CacheState>(
          builder: (context, cacheState) {
            final isLoading = cacheState is CacheLoading;
            final totalFiles = cacheState is CacheLoaded ? cacheState.totalFiles : 0;
            final sizeInMB = cacheState is CacheLoaded ? cacheState.sizeInMB : 0.0;

            return ListView(
              children: [
                // Cache Summary Card
                Card(
                  margin: const EdgeInsets.all(16.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          localizations.cacheSummary,
                          style: titleMedium,
                        ),
                        const SizedBox(height: 16),
                        _buildCacheInfoTile(
                          icon: Icons.file_present,
                          title: localizations.cachedFiles,
                          isLoading: isLoading,
                          value: '$totalFiles',
                          theme: theme,
                        ),
                        const Divider(),
                        _buildCacheInfoTile(
                          icon: Icons.storage,
                          title: localizations.cacheSize,
                          isLoading: isLoading,
                          value: '${sizeInMB.toStringAsFixed(_decimalPlaces)} MB',
                          theme: theme,
                        ),
                      ],
                    ),
                  ),
                ),

                // Information Card
                Card(
                  margin: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(Icons.info_outline, color: theme.colorScheme.primary),
                            const SizedBox(width: 8),
                            Text(
                              localizations.aboutCache,
                              style: titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          localizations.cacheDescription,
                        ),
                        const SizedBox(height: 8),
                        Text(
                          localizations.cacheRemovalInfo(
                            AppConstants.cacheStalePeriod.inDays,
                            AppConstants.maxCacheObjects,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),

                // Clear Cache Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: ElevatedButton.icon(
                    onPressed: totalFiles > 0 && !isLoading && cacheState is CacheLoaded
                        ? () => _showClearCacheDialog(context, cacheState)
                        : null,
                    icon: const Icon(Icons.delete_sweep),
                    label: Text(localizations.clearCache),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.colorScheme.error,
                      foregroundColor: theme.colorScheme.onError,
                      disabledBackgroundColor: theme.disabledColor,
                      padding: const EdgeInsets.symmetric(vertical: 16.0),
                    ),
                  ),
                ),
                
                const SizedBox(height: 16),
              ],
            );
          },
        ),
      ),
    );
  }
}