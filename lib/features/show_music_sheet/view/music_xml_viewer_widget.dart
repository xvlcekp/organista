import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:flutter_hooks/flutter_hooks.dart';
import 'package:organista/features/show_music_sheet/view/music_sheet_view.dart';
import 'package:organista/features/show_music_sheet/view/music_xml_controls_overlay.dart';
import 'package:organista/features/show_music_sheet/view/page_navigation.dart';
import 'package:organista/logger/custom_logger.dart';
import 'package:organista/features/show_music_sheet/view/music_xml_thumbnail_widget.dart';
import 'package:organista/features/show_music_sheet/view/sheet_load_error.dart';
import 'package:organista/features/show_playlist/bloc/playlist_bloc.dart';
import 'package:organista/models/music_sheets/music_sheet_source.dart';
import 'package:provider/provider.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MusicXmlViewerWidget extends HookWidget {
  const MusicXmlViewerWidget({
    super.key,
    required this.source,
    this.mode = MusicSheetViewMode.full,
    this.showOverlays = true,
    this.onSheetTap,
  });

  final MusicSheetSource source;
  final MusicSheetViewMode mode;

  /// Whether the controls (page counter, transposition label, settings button) are shown.
  final bool showOverlays;

  /// Called when the page JavaScript reports a tap on the sheet.
  final VoidCallback? onSheetTap;

  static const int _kChannelPrefixLength = 2;

  /// LYRICS_PADDING_DENSE in `musicXml_display.html`; the page posts the sheet's value after loading.
  static const double _kDefaultLyricsPadding = 0.5;

  /// Parses the `p:<current>/<count>` message the page JavaScript posts after
  /// every render and page turn; null when the message is malformed.
  @visibleForTesting
  static (int, int)? parsePageMessage(String message) {
    if (!message.startsWith('p:')) return null;
    final parts = message.substring(_kChannelPrefixLength).split('/');
    if (parts.length != 2) return null;
    final current = int.tryParse(parts[0]);
    final count = int.tryParse(parts[1]);
    if (current == null || count == null || count < 1 || current < 1 || current > count) return null;
    return (current, count);
  }

  Future<WebViewController> _initializeWebView(
    BuildContext context,
    String fileData,
    ValueNotifier<int> currentTranspose,
    ValueNotifier<double> currentLyricsPadding,
    ValueNotifier<(int, int)> pages,
    MusicSheetUrlSource? urlSource,
  ) async {
    // Captured before any await
    final playlistBloc = context.read<PlaylistBloc>();

    final controller = WebViewController();
    controller
      // ignore: unawaited_futures Communication with the native platform
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      // ignore: unawaited_futures Communication with the native platform
      ..setOnConsoleMessage((message) {
        // Only JS errors are worth a warning; `console.log` output (e.g. render timings) stays at debug.
        if (message.level == JavaScriptLogLevel.error) {
          logger.w('[WebView] ${message.message}');
        } else {
          logger.d('[WebView] ${message.message}');
        }
      })
      // ignore: unawaited_futures Communication with the native platform
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            controller.runJavaScript(
              'initSheet(${jsonEncode(fileData)}, ${currentTranspose.value})',
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
              // Only a stored sheet has a transposition to persist; picked bytes are not saved yet.
              if (urlSource != null) {
                playlistBloc.add(
                  UpdateMusicSheetTranspositionEvent(
                    musicSheet: urlSource.musicSheet,
                    transposition: val,
                  ),
                );
              }
            }
          } else if (msg.startsWith('l:')) {
            final val = double.tryParse(msg.characters.getRange(_kChannelPrefixLength).string);
            if (val != null) currentLyricsPadding.value = val;
          }
        },
      )
      // ignore: unawaited_futures Communication with the native platform
      ..addJavaScriptChannel(
        'PageChannel',
        onMessageReceived: (JavaScriptMessage message) {
          if (message.message == 'tap') {
            onSheetTap?.call();
            return;
          }
          final parsed = parsePageMessage(message.message);
          if (parsed != null) pages.value = parsed;
        },
      )
      // ignore: unawaited_futures Communication with the native platform
      ..loadFlutterAsset('assets/html/musicXml_display.html');
    return controller;
  }

  /// Resolves the sheet to a base64 data URL the page can load offline, or null when a url source cannot be
  /// fetched (not on the device and no network). Handing the page the remote URL instead would leave it on its
  /// own loading spinner forever, since the fetch inside the page fails for the same reason.
  Future<String?> _loadFileData(CacheManager cacheManager) async {
    final Uint8List bytes;
    switch (source) {
      case MusicSheetBytesSource(bytes: final fileBytes):
        bytes = fileBytes;
      case MusicSheetUrlSource(:final musicSheet):
        try {
          final cachedFile = await cacheManager.getSingleFile(musicSheet.fileUrl);
          bytes = await cachedFile.readAsBytes();
        } catch (e) {
          logger.w('MusicXML sheet ${musicSheet.fileName} is not on the device and could not be fetched', error: e);
          return null;
        }
    }
    // Offloaded to a background isolate because encoding large files on the main thread causes ANRs
    // on budget devices.
    final encoded = await compute(base64Encode, bytes);
    return 'data:application/octet-stream;base64,$encoded';
  }

  Future<void> _initialize(
    BuildContext context,
    ValueNotifier<WebViewController?> controller,
    ValueNotifier<bool> loadFailed,
    ValueNotifier<int> currentTranspose,
    ValueNotifier<double> currentLyricsPadding,
    ValueNotifier<(int, int)> pages,
    MusicSheetUrlSource? urlSource,
  ) async {
    try {
      final fileData = await _loadFileData(context.read<CacheManager>());
      if (fileData == null) {
        loadFailed.value = true;
        return;
      }
      if (context.mounted) {
        controller.value = await _initializeWebView(
          context,
          fileData,
          currentTranspose,
          currentLyricsPadding,
          pages,
          urlSource,
        );
      }
    } catch (e, st) {
      logger.e('Failed to initialize MusicXML viewer', error: e, stackTrace: st);
    }
  }

  @override
  Widget build(BuildContext context) {
    final urlSource = source is MusicSheetUrlSource ? source as MusicSheetUrlSource : null;
    final currentTranspose = useState(urlSource?.musicSheet.transposition ?? 0);
    final currentLyricsPadding = useState(_kDefaultLyricsPadding);
    // (current page, page count) of the rendered sheet
    final pages = useState<(int, int)>((1, 1));
    final controller = useState<WebViewController?>(null);
    final loadFailed = useState(false);

    useEffect(() {
      if (mode == MusicSheetViewMode.thumbnail) return null;
      _initialize(context, controller, loadFailed, currentTranspose, currentLyricsPadding, pages, urlSource);
      return null;
    }, const []);

    if (mode == MusicSheetViewMode.thumbnail) {
      return MusicXmlThumbnailWidget(
        fileUrl: urlSource!.musicSheet.fileUrl,
        sequenceId: urlSource.musicSheet.sequenceId,
      );
    }

    if (loadFailed.value) {
      return SheetLoadError(mode: mode);
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
          PageNavigation(
            currentPage: pages.value.$1,
            pageCount: pages.value.$2,
            onPrevious: () => wvc.runJavaScript('prevPage()'),
            onNext: () => wvc.runJavaScript('nextPage()'),
          ),
        if (mode == MusicSheetViewMode.full && showOverlays)
          MusicXmlControlsOverlay(
            currentTranspose: currentTranspose.value,
            currentLyricsPadding: currentLyricsPadding.value,
            wvc: wvc,
            currentPage: pages.value.$1,
            pageCount: pages.value.$2,
          ),
      ],
    );
  }
}
