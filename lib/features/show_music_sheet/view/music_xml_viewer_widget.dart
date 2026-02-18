import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_cache_manager/flutter_cache_manager.dart';
import 'package:http/http.dart' as http;
import 'package:organista/models/music_sheets/music_sheet.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MusicXmlViewerWidget extends StatefulWidget {
  const MusicXmlViewerWidget({
    super.key,
    required this.musicSheet,
  });

  final MusicSheet musicSheet;

  @override
  State<MusicXmlViewerWidget> createState() => _MusicXmlViewerWidgetState();
}

class _MusicXmlViewerWidgetState extends State<MusicXmlViewerWidget> with SingleTickerProviderStateMixin {
  WebViewController? _controller;
  bool _isLoading = true;
  String? _errorMessage;
  int _currentTranspose = 0;

  late AnimationController _animationController;
  late Animation<double> _expandAnimation;
  bool _isMenuOpen = false;

  static const double _kItemSpacing = 8.0;
  static const double _kGroupSpacing = 16.0;

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(vsync: this, duration: const Duration(milliseconds: 250));
    _expandAnimation = CurvedAnimation(
      parent: _animationController,
      curve: Curves.fastOutSlowIn,
    );
    _initializeWebView();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _initializeWebView() async {
    try {
      String musicXmlContent;
      if (kIsWeb) {
        final response = await http.get(Uri.parse(widget.musicSheet.fileUrl));
        musicXmlContent = response.body;
      } else {
        final cacheManager = context.read<CacheManager>();
        final file = await cacheManager.getSingleFile(widget.musicSheet.fileUrl);
        musicXmlContent = await file.readAsString();
      }

      final osmdLibraryContent = await rootBundle.loadString(
        'assets/js/opensheetmusicdisplay.min.js',
      );
      // Ensure no script tags in the library break the HTML
      final safeOsmdLibraryContent = osmdLibraryContent.replaceAll('</script>', '<\\/script>');

      final htmlContent = _createHtmlContent(musicXmlContent, safeOsmdLibraryContent);

      final controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setBackgroundColor(const Color(0x00000000))
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageFinished: (String url) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            },
            onWebResourceError: (WebResourceError error) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                  _errorMessage = 'Failed to load: ${error.description}';
                });
              }
            },
          ),
        )
        ..addJavaScriptChannel(
          'FlutterChannel',
          onMessageReceived: (JavaScriptMessage message) {
            if (!mounted) return;
            if (message.message.startsWith('transpose:')) {
              final transposeValue = int.tryParse(message.message.split(':')[1]);
              if (transposeValue != null) {
                setState(() => _currentTranspose = transposeValue);
              }
            }
          },
        )
        ..loadHtmlString(htmlContent);

      if (mounted) {
        setState(() {
          _controller = controller;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoading = false;
          _errorMessage = 'Error loading MusicXML: $e';
        });
      }
    }
  }

  void _zoomIn() {
    _controller?.runJavaScript('zoomIn()');
  }

  void _zoomOut() {
    _controller?.runJavaScript('zoomOut()');
  }

  void _transposeUp() {
    _controller?.runJavaScript('transposeUp()');
  }

  void _transposeDown() {
    _controller?.runJavaScript('transposeDown()');
  }

  void _resetTranspose() {
    _controller?.runJavaScript('resetTranspose()');
  }

  String _createHtmlContent(String musicXmlContent, String osmdLibraryContent) {
    // Escape closing script tags to prevent breaking the HTML
    final safeXml = musicXmlContent.replaceAll('</script>', '<\\/script>');
    // Minimal HTML with OSMD
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
    <title>MusicXML Display</title>
    <script>
      $osmdLibraryContent
    </script>
    <style>
        html {
            background-color: #f0f0f0;
        }
        body {
            margin: 0;
            padding: 0;
            font-family: Arial, sans-serif;
            background-color: #f0f0f0;
            display: flex;
            flex-direction: column;
            align-items: center;
            min-height: 100vh;
            overflow: auto;
            -webkit-overflow-scrolling: touch;
            touch-action: pan-y pan-x; /* Explicitly allow multi-directional panning */
        }
        #osmdContainer {
            width: fit-content;
            min-width: 100%;
            padding: 20px 0;
            display: flex;
            flex-direction: column;
            align-items: center;
            box-sizing: border-box;
        }
        /* Style for SVG pages generated by OSMD */
        svg {
            background-color: white !important;
            box-shadow: 0 4px 8px rgba(0,0,0,0.2);
            margin-bottom: 20px;
            display: block !important;
            max-width: none !important; /* Allow growth beyond viewport when zoomed */
        }
        /* Make all note elements bolder */
        svg path,
        svg rect,
        svg line,
        svg circle,
        svg ellipse {
            stroke-width: 2.5 !important; /* Make all strokes thicker */
            paint-order: stroke fill; /* Ensure stroke is visible */
        }
        /* Specifically target note heads to make them bolder */
        svg path[d*="M"] {
            stroke: black !important;
            stroke-width: 1.5 !important;
        }
        /* Make staff lines and stems more prominent */
        svg line {
            stroke-width: 2.0 !important;
        }
        /* Apply a slight contrast boost to make everything crisper */
        svg {
            filter: contrast(1.15);
        }
        .osmdPage {
            /* Handled by SVG selector above */
        }
        .error { color: red; padding: 20px; }
        .loading { 
            position: fixed;
            top: 50%;
            left: 50%;
            transform: translate(-50%, -50%);
            text-align: center; 
            z-index: 100;
        }
    </style>
</head>
<body>
    <div id="osmdContainer"></div>
    <div id="status" class="loading">Loading music notation...</div>
    
    <script id="musicXmlData" type="application/vnd.recordare.musicxml+xml">
$safeXml
    </script>
    <script>
        let osmd = null;
        let currentZoom = 1.0;
        let currentTranspose = 0;
        let baseWidth = 1000; // Reference width for A4 layout
        
        async function loadMusicXML() {
            try {
                const musicXmlContent = document.getElementById('musicXmlData').textContent;
                osmd = new opensheetmusicdisplay.OpenSheetMusicDisplay("osmdContainer", {
                    newSystemFromXML: true,
                    newPageFromXML: true,
                    autoResize: false, // Prevent reflow when container size or zoom changes
                    backend: "svg",
                    drawTitle: true,
                    followCursor: false,
                    pageFormat: "A4_P",
                });

                osmd.setOptions({
                    drawingParameters: "all", // Changed to all to ensure credits/extra verses are processed
                    drawPartNames: false,
                    drawPartAbbreviations: false,
                    drawTitle: true,              // Ensure title stays visible with "all"
                    drawCredits: true,            // Enable rendering of extra verses/credits
                    pageFormat: "A4_P",
                    renderSingleHorizontalStaffline: false,
                    engravingRules: {
                        LyricsAlignment: 0,
                        RenderVerseNumbers: false,
                        RenderCredits: true,      // Explicitly render credits/verses
                        CompactMode: false,
                        VoiceSpacingMultiplier: 0.65,
                        VoiceSpacingAddend: 2.0,
                        MinSkyBottomDistBetweenStaves: 1.0,
                        MinSkyBottomDistBetweenSystems: 1.0,
                        BetweenStaffDistance: 2.5,
                        StaffDistance: 3.5,
                        MinSystemDistance: 1.0,
                        PageTopMargin: 10.0,
                        PageBottomMargin: 10.0, // Added margin
                        PageLeftMargin: 2.0,
                        PageRightMargin: 2.0,
                        MinNoteDistance: 1.0
                    }
                });

                await osmd.load(musicXmlContent);
                
                // Initialize tools
                osmd.TransposeCalculator = new opensheetmusicdisplay.TransposeCalculator();
                
                await fitToPage(); // Try to fit page initially for A4
                osmd.render();

                // Explicitly set transpose and update graphic to ensure correct rendering
                setTimeout(() => {
                    try {
                        osmd.Sheet.Transpose = 0;
                        osmd.updateGraphic();
                        osmd.render();
                        
                        // Add class to generated SVG elements for styling
                        const svgs = document.querySelectorAll('#osmdContainer svg');
                        svgs.forEach(svg => svg.classList.add('osmdPage'));
                    } catch (e) {
                        console.error('Error applying initial fix:', e);
                    }
                }, 100);
                
                document.getElementById('status').style.display = 'none';
            } catch (error) {
                console.error('Error loading music:', error);
                document.getElementById('status').className = 'error';
                document.getElementById('status').textContent = 'Error: ' + error.message;
            }
        }
        
        async function fitToPage() {
            if (!osmd) return;
            try {
                // Determine a stable width for A4 layout. 
                const containerWidth = window.innerWidth - 40;
                // OSMD's internal base width for A4 is roughly 800-900 units.
                // We use baseWidth = 1000 as a virtual reference.
                // Subtract 0.1 to start one "zoom out" step smaller as requested.
                currentZoom = (containerWidth / (baseWidth * 0.82)) - 0.1; 
                
                updateView();
            } catch (e) {
                console.warn(e);
            }
        }
        
        function zoomIn() {
            if (!osmd) return;
            currentZoom = Math.min(currentZoom + 0.1, 5.0);
            updateView();
        }
        
        function zoomOut() {
            if (!osmd) return;
            currentZoom = Math.max(currentZoom - 0.1, 0.1);
            updateView();
        }

        function updateView() {
            // Don't constrain container width - let it grow/shrink naturally with zoom
            // This allows newSystemFromXML and newPageFromXML to work properly
            // The container will use 'width: fit-content' from CSS
            osmd.zoom = currentZoom;
            osmd.render();
        }
        
        function transposeUp() {
            updateTranspose(currentTranspose + 1);
        }
        function transposeDown() {
            updateTranspose(currentTranspose - 1);
        }
        function resetTranspose() {
            updateTranspose(0);
        }
        function updateTranspose(val) {
           if (!osmd || !osmd.Sheet) return;
           currentTranspose = Math.max(-12, Math.min(12, val));
           try {
               osmd.Sheet.Transpose = currentTranspose;
               osmd.updateGraphic();
               updateView();
               FlutterChannel.postMessage('transpose:' + currentTranspose);
               // Re-apply visibility in single page mode if needed, though render might reset it
               // For now, let's assume specific visibility handling might be needed if render resets DOM
           } catch (e) { console.error(e); }
        }
        
        window.addEventListener('load', loadMusicXML);
        window.addEventListener('resize', async () => { 
            if(osmd) {
                await fitToPage();
                osmd.render();
                // Re-apply class
                const svgs = document.querySelectorAll('#osmdContainer svg');
                svgs.forEach(svg => svg.classList.add('osmdPage'));
            }
        });
    </script>
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(Icons.error_outline, color: Colors.red, size: 48),
              const SizedBox(height: 16),
              Text(
                _errorMessage!,
                textAlign: TextAlign.center,
                style: const TextStyle(color: Colors.red),
              ),
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: () {
                  setState(() {
                    _errorMessage = null;
                    _isLoading = true;
                  });
                  _initializeWebView();
                },
                child: const Text('Retry'),
              ),
            ],
          ),
        ),
      );
    }

    if (_isLoading) {
      return const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircularProgressIndicator(),
            SizedBox(height: 16),
            Text('Loading music notation...'),
          ],
        ),
      );
    }

    if (_controller == null) {
      return const Center(child: CircularProgressIndicator());
    }

    final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;

    return Stack(
      children: [
        WebViewWidget(
          controller: _controller!,
          gestureRecognizers: {
            Factory<VerticalDragGestureRecognizer>(() => VerticalDragGestureRecognizer()),
            Factory<HorizontalDragGestureRecognizer>(() => HorizontalDragGestureRecognizer()),
            Factory<ScaleGestureRecognizer>(() => ScaleGestureRecognizer()),
            Factory<TapGestureRecognizer>(() => TapGestureRecognizer()),
          },
        ),
        Positioned(
          right: 16,
          bottom: 16,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (_currentTranspose != 0)
                Container(
                  padding: const EdgeInsets.all(8),
                  margin: const EdgeInsets.only(bottom: 8),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    'Transpose: ${_currentTranspose > 0 ? '+' : ''}$_currentTranspose',
                    style: const TextStyle(color: Colors.white),
                  ),
                ),
              Flex(
                direction: isLandscape ? Axis.horizontal : Axis.vertical,
                mainAxisAlignment: MainAxisAlignment.end,
                crossAxisAlignment: CrossAxisAlignment.center,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Flexible(
                    child: SingleChildScrollView(
                      scrollDirection: isLandscape ? Axis.horizontal : Axis.vertical,
                      reverse: true,
                      child: SizeTransition(
                        sizeFactor: _expandAnimation,
                        axis: isLandscape ? Axis.horizontal : Axis.vertical,
                        axisAlignment: -1.0,
                        child: Flex(
                          direction: isLandscape ? Axis.horizontal : Axis.vertical,
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            FloatingActionButton(
                              heroTag: 'zoom_in',
                              mini: true,
                              onPressed: _zoomIn,
                              tooltip: 'Zoom In',
                              child: const Icon(Icons.zoom_in),
                            ),
                            SizedBox(width: isLandscape ? _kItemSpacing : 0, height: isLandscape ? 0 : _kItemSpacing),
                            FloatingActionButton(
                              heroTag: 'zoom_out',
                              mini: true,
                              onPressed: _zoomOut,
                              tooltip: 'Zoom Out',
                              child: const Icon(Icons.zoom_out),
                            ),
                            SizedBox(width: isLandscape ? _kGroupSpacing : 0, height: isLandscape ? 0 : _kGroupSpacing),
                            FloatingActionButton(
                              heroTag: 'transpose_up',
                              mini: true,
                              onPressed: _transposeUp,
                              tooltip: 'Transpose Up',
                              child: const Icon(Icons.arrow_upward),
                            ),
                            SizedBox(width: isLandscape ? _kItemSpacing : 0, height: isLandscape ? 0 : _kItemSpacing),
                            FloatingActionButton(
                              heroTag: 'transpose_down',
                              mini: true,
                              onPressed: _transposeDown,
                              tooltip: 'Transpose Down',
                              child: const Icon(Icons.arrow_downward),
                            ),
                            SizedBox(width: isLandscape ? _kItemSpacing : 0, height: isLandscape ? 0 : _kItemSpacing),
                            FloatingActionButton(
                              heroTag: 'reset_transpose',
                              mini: true,
                              onPressed: _resetTranspose,
                              tooltip: 'Reset Transpose',
                              child: const Text('0', style: TextStyle(fontWeight: FontWeight.bold)),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                  FloatingActionButton(
                    heroTag: 'menu',
                    onPressed: () {
                      setState(() {
                        _isMenuOpen = !_isMenuOpen;
                        if (_isMenuOpen) {
                          _animationController.forward();
                        } else {
                          _animationController.reverse();
                        }
                      });
                    },
                    backgroundColor: _isMenuOpen ? Colors.grey : Theme.of(context).primaryColor,
                    child: Icon(_isMenuOpen ? Icons.close : Icons.tune),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }
}
