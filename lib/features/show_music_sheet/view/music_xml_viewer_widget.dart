import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:organista/features/show_music_sheet/view/music_sheet_view.dart';
import 'package:organista/features/show_music_sheet/view/music_xml_controls_overlay.dart';
import 'package:organista/logger/custom_logger.dart';
import 'package:organista/features/show_music_sheet/view/music_xml_thumbnail_widget.dart';
import 'package:organista/features/show_playlist/bloc/playlist_bloc.dart';
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MusicXmlViewerWidget extends HookWidget {
  const MusicXmlViewerWidget({
    super.key,
    required this.musicSheet,
    this.mode = MusicSheetViewMode.full,
  });

  final MusicSheet musicSheet;
  final MusicSheetViewMode mode;

  static const int _kChannelPrefixLength = 2;

  Future<WebViewController> _initializeWebView(
    BuildContext context,
    ValueNotifier<int> currentTranspose,
    ValueNotifier<double> currentElongationFactor,
  ) async {
    // Capture context-dependent objects BEFORE any await
    final cacheManager = context.read<CacheManager>();
    final playlistBloc = context.read<PlaylistBloc>();
    // Get cached file bytes for offline support
    String fileData;
    try {
      final cachedFile = await cacheManager.getSingleFile(musicSheet.fileUrl);
      final bytes = await cachedFile.readAsBytes();
      // Convert to base64 data URL for offline loading — offloaded to a
      // background isolate because encoding large files on the main thread
      // causes ANRs on budget devices.
      final encoded = await compute(base64Encode, bytes);
      fileData = 'data:application/octet-stream;base64,$encoded';
    } catch (e) {
      // Fallback to URL if cache is not available
      fileData = musicSheet.fileUrl;
    }

    final controller = WebViewController();
    controller
      // ignore: unawaited_futures Communication with the native platform
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // ignore: unawaited_futures Communication with the native platform
      ..setOnConsoleMessage((message) {
        logger.w('[WebView] ${message.message}');
      })
      // ignore: unawaited_futures Communication with the native platform
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            controller.runJavaScript(
              'initSheet(${jsonEncode(fileData)}, ${musicSheet.transposition})',
            );
          },
        ),
      )
      // ignore: unawaited_futures Communication with the native platform
      ..addJavaScriptChannel(
        'TransposeChannel',
        onMessageReceived: (JavaScriptMessage message) {
          final msg = message.message;
          if (msg.startsWith('t:')) {
            final val = int.tryParse(msg.characters.getRange(_kChannelPrefixLength).string);
            if (val != null) {
              currentTranspose.value = val;
              playlistBloc.add(
                UpdateMusicSheetTranspositionEvent(
                  musicSheet: musicSheet,
                  transposition: val,
                ),
              );
            }
          } else if (msg.startsWith('e:')) {
            final val = double.tryParse(msg.characters.getRange(_kChannelPrefixLength).string);
            if (val != null) currentElongationFactor.value = val;
          }
        },
      )
      // ignore: unawaited_futures Communication with the native platform
      ..loadFlutterAsset('assets/html/musicXml_display.html');
    return controller;
  }

  Future<void> _initialize(
    BuildContext context,
    ValueNotifier<WebViewController?> controller,
    ValueNotifier<int> currentTranspose,
    ValueNotifier<double> currentElongationFactor,
  ) async {
    try {
      if (context.mounted) {
        controller.value = await _initializeWebView(context, currentTranspose, currentElongationFactor);
      }
    } catch (e, st) {
      logger.e('Failed to initialize MusicXML viewer', error: e, stackTrace: st);
    }
  }

  @override
  Widget build(BuildContext context) {
    final currentTranspose = useState(musicSheet.transposition);
    final currentElongationFactor = useState(1.0);
    final controller = useState<WebViewController?>(null);

    useEffect(() {
      if (mode == MusicSheetViewMode.thumbnail) return null;
      _initialize(context, controller, currentTranspose, currentElongationFactor);
      return null;
    }, const []);

    if (mode == MusicSheetViewMode.thumbnail) {
      return MusicXmlThumbnailWidget(sequenceId: musicSheet.sequenceId);
    }

    final wvc = controller.value;
    if (wvc == null) {
      return const Center(child: CircularProgressIndicator());
    }

    return Stack(
      children: [
        WebViewWidget(
          controller: wvc,
          gestureRecognizers: {
            Factory<VerticalDragGestureRecognizer>(() => VerticalDragGestureRecognizer()),
          },
        ),
        if (mode == MusicSheetViewMode.full)
          MusicXmlControlsOverlay(
            currentTranspose: currentTranspose.value,
            currentElongationFactor: currentElongationFactor.value,
            wvc: wvc,
          ),
      ],
    );
  }
}
