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

class MsczViewerWidget extends StatefulWidget {
  const MsczViewerWidget({
    super.key,
    required this.musicSheet,
  });

  final MusicSheet musicSheet;

  @override
  State<MsczViewerWidget> createState() => _MsczViewerWidgetState();
}

class _MsczViewerWidgetState extends State<MsczViewerWidget> with SingleTickerProviderStateMixin {
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
      String fileUrl = widget.musicSheet.fileUrl;

      final museScoreLibraryContent = await rootBundle.loadString(
        'assets/js/musescore-display.min.js',
      );
      // Ensure no script tags in the library break the HTML
      final safeLibraryContent = museScoreLibraryContent.replaceAll('</script>', '<\\/script>');

      final htmlContent = _createHtmlContent(fileUrl, safeLibraryContent);

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

  String _createHtmlContent(String fileUrl, String museScoreLibraryContent) {
    // Create HTML with musescore-display library
    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
    <title>MuseScore Display</title>
    <script>
      $museScoreLibraryContent
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
        #score-container {
            /* A4 width: 210mm = 595px at 72 DPI */
            width: 595px;
            padding: 20px 0;
            display: flex;
            flex-direction: column;
            align-items: center;
            box-sizing: border-box;
            margin: 0 auto;
        }
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
    <div id="score-container"></div>
    <div id="status" class="loading">Loading music notation...</div>
    <script>
        let display = null;
        let currentZoom = 1.0;
        let currentTranspose = 0;
        let baseWidth = 1000;

        async function loadMuseScore() {
            try {
                // Initialize MuseScoreDisplay with A4 Portrait format
                display = new musescoreDisplay.MuseScoreDisplay("score-container", {
                    autoResize: false,
                    zoom: 1.0,
                    drawingParameters: "default"
                });

                // Load the file from URL
                await display.load("$fileUrl");

                // Set page format to A4 Portrait (fixed width, no horizontal wrapping)
                await display.setPageFormat("A4_P");

                // Set initial zoom for comfortable viewing
                await fitToPage();

                document.getElementById('status').style.display = 'none';
            } catch (error) {
                console.error('Error loading music:', error);
                document.getElementById('status').className = 'error';
                document.getElementById('status').textContent = 'Error: ' + error.message;
            }
        }
        
        async function fitToPage() {
            if (!display) return;
            try {
                // A4 width is approximately 210mm = 595 pixels (at 72 DPI)
                // Set zoom to fit A4 width with some padding for comfortable viewing
                const a4WidthPx = 595;
                const containerWidth = window.innerWidth - 40;
                currentZoom = Math.max(0.5, Math.min(1.2, containerWidth / a4WidthPx));
                display.zoom = currentZoom;
            } catch (e) {
                console.warn(e);
            }
        }

        function zoomIn() {
            if (!display) return;
            currentZoom = Math.min(currentZoom + 0.15, 3.0);
            display.zoom = currentZoom;
        }

        function zoomOut() {
            if (!display) return;
            currentZoom = Math.max(currentZoom - 0.15, 0.5);
            display.zoom = currentZoom;
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
            if (!display) return;
            currentTranspose = Math.max(-12, Math.min(12, val));
            try {
                display.transpose(currentTranspose);
                FlutterChannel.postMessage('transpose:' + currentTranspose);
            } catch (e) {
                console.error('Transpose error:', e);
            }
        }

        window.addEventListener('load', loadMuseScore);
        window.addEventListener('resize', async () => {
            if (display) {
                await fitToPage();
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
                              heroTag: null,
                              mini: true,
                              onPressed: _zoomIn,
                              tooltip: 'Zoom In',
                              child: const Icon(Icons.zoom_in),
                            ),
                            SizedBox(width: isLandscape ? _kItemSpacing : 0, height: isLandscape ? 0 : _kItemSpacing),
                            FloatingActionButton(
                              heroTag: null,
                              mini: true,
                              onPressed: _zoomOut,
                              tooltip: 'Zoom Out',
                              child: const Icon(Icons.zoom_out),
                            ),
                            SizedBox(width: isLandscape ? _kGroupSpacing : 0, height: isLandscape ? 0 : _kGroupSpacing),
                            FloatingActionButton(
                              heroTag: null,
                              mini: true,
                              onPressed: _transposeUp,
                              tooltip: 'Transpose Up',
                              child: const Icon(Icons.arrow_upward),
                            ),
                            SizedBox(width: isLandscape ? _kItemSpacing : 0, height: isLandscape ? 0 : _kItemSpacing),
                            FloatingActionButton(
                              heroTag: null,
                              mini: true,
                              onPressed: _transposeDown,
                              tooltip: 'Transpose Down',
                              child: const Icon(Icons.arrow_downward),
                            ),
                            SizedBox(width: isLandscape ? _kItemSpacing : 0, height: isLandscape ? 0 : _kItemSpacing),
                            FloatingActionButton(
                              heroTag: null,
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
                    heroTag: null,
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
