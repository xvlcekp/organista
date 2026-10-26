import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:organista/extensions/buildcontext/localization.dart';
import 'package:organista/features/connectivity/cubit/connectivity_cubit.dart';
import 'package:organista/features/show_music_sheet/view/music_sheet_view.dart';

/// Shown in place of a sheet that could not be loaded. Offline, the likely cause is named: the sheet was never
/// downloaded to this device.
class SheetLoadError extends StatelessWidget {
  final MusicSheetViewMode mode;

  const SheetLoadError({super.key, required this.mode});

  @override
  Widget build(BuildContext context) {
    // The full-screen viewer has a black background and no Material ancestor; the other modes sit on a Scaffold.
    final color = mode == MusicSheetViewMode.full ? Colors.white : Theme.of(context).colorScheme.onSurface;
    final isOnline = context.watch<ConnectivityCubit?>()?.state.isOnline ?? true;
    if (isOnline) {
      return Center(child: Icon(Icons.error, color: color));
    }
    if (mode == MusicSheetViewMode.thumbnail) {
      return Center(child: Icon(Icons.cloud_off, color: color));
    }
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.cloud_off, color: color),
            const SizedBox(height: 8),
            Text(
              context.loc.sheetNotAvailableOffline,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(color: color),
            ),
          ],
        ),
      ),
    );
  }
}
