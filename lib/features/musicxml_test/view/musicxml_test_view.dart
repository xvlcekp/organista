import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';

class MusicXmlTestView extends StatefulWidget {
  const MusicXmlTestView({super.key});

  @override
  State<MusicXmlTestView> createState() => _MusicXmlTestViewState();
}

class _MusicXmlTestViewState extends State<MusicXmlTestView> {
  WebViewController? _controller;
  bool _isLoading = true;
  String? _errorMessage;
  int _currentTranspose = 0;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  Future<void> _initializeWebView() async {
    try {
      // Load the MusicXML file from assets
      final musicXmlContent = await rootBundle.loadString(
        'assets/musicxml/hello_world.musicxml',
      );

      // Create the HTML content with OpenSheetMusicDisplay
      final htmlContent = _createHtmlContent(musicXmlContent);

      // Initialize the WebView controller
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
            // Handle messages from JavaScript
            if (message.message.startsWith('transpose:')) {
              // Handle transpose updates
              final transposeValue = int.tryParse(message.message.split(':')[1]);
              if (transposeValue != null) {
                setState(() => _currentTranspose = transposeValue);
              }
            }
          },
        )
        ..loadHtmlString(htmlContent);

      setState(() {
        _controller = controller;
      });
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

  String _createHtmlContent(String musicXmlContent) {
    // Escape closing script tags to prevent breaking the HTML
    final safeXml = musicXmlContent.replaceAll('</script>', '<\\/script>');

    return '''
<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <meta name="viewport" content="width=device-width, initial-scale=1.0, user-scalable=no">
    <title>MusicXML Display</title>
    <script src="https://cdn.jsdelivr.net/npm/opensheetmusicdisplay@1.8.7/build/opensheetmusicdisplay.min.js"></script>
    <style>
        body {
            margin: 0;
            padding: 0;
            font-family: Arial, sans-serif;
            background-color: #ffffff;
            overflow: hidden;
        }
        #osmdContainer {
            width: 100%;
            height: 100vh;
            overflow: auto;
            padding: 10px;
            box-sizing: border-box;
        }
        .error {
            color: red;
            padding: 20px;
        }
        .loading {
            padding: 20px;
            text-align: center;
        }
    </style>
</head>
<body>
    <div id="osmdContainer"></div>
    <div id="status" class="loading">Loading music notation...</div>
    
    <!-- Embed MusicXML safely -->
    <script id="musicXmlData" type="application/vnd.recordare.musicxml+xml">
$safeXml
    </script>

    <script>
        let osmd = null;
        let currentZoom = 1.0;
        
        async function loadMusicXML() {
            try {
                const musicXmlContent = document.getElementById('musicXmlData').textContent;
                
                osmd = new opensheetmusicdisplay.OpenSheetMusicDisplay("osmdContainer", {
                    autoResize: false,
                    backend: "svg",
                    drawTitle: true,
                    followCursor: true,
                });

                await osmd.load(musicXmlContent);
                
                // Initialize tools
                osmd.TransposeCalculator = new opensheetmusicdisplay.TransposeCalculator();
                
                // Initial render
                await fitToWidth();
                osmd.render();
                
                // Show cursor
                osmd.cursor.show();
                
                document.getElementById('status').style.display = 'none';
            } catch (error) {
                console.error('Error loading music:', error);
                document.getElementById('status').className = 'error';
                document.getElementById('status').textContent = 'Error: ' + error.message;
            }
        }
        
        async function fitToWidth() {
            if (!osmd) return;
            try {
                // Determine zoom to fit width
                const container = document.getElementById('osmdContainer');
                const width = container.clientWidth - 20;
                // A rough estimation or rely on auto-resize if enabled, 
                // but we disabled autoResize for control. 
                // For simplicity in this "revert", we'll just set a reasonable zoom
                // or rely on the previous logic if it was working well.
                // Let's use a simple zoom calculation based on standard sheet width (e.g. 1000px)
                const targetZoom = width / 1200; 
                currentZoom = Math.max(0.5, Math.min(targetZoom * 1.5, 2.0)); 
                osmd.zoom = currentZoom;
            } catch (e) {
                console.warn(e);
            }
        }
        
        function zoomIn() {
            if (!osmd) return;
            currentZoom = Math.min(currentZoom + 0.2, 3.0);
            osmd.zoom = currentZoom;
            osmd.render();
        }
        
        function zoomOut() {
            if (!osmd) return;
            currentZoom = Math.max(currentZoom - 0.2, 0.5);
            osmd.zoom = currentZoom;
            osmd.render();
        }
        
        // Transposition
        let currentTranspose = 0;
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
               osmd.render();
               FlutterChannel.postMessage('transpose:' + currentTranspose);
           } catch (e) { console.error(e); }
        }

        window.addEventListener('load', loadMusicXML);
        window.addEventListener('resize', () => { if(osmd) fitToWidth(); });
    </script>
</body>
</html>
''';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('MusicXML Test'),
            if (_currentTranspose != 0)
              Text(
                'Transpose: ${_currentTranspose > 0 ? '+' : ''}$_currentTranspose',
                style: const TextStyle(fontSize: 12),
              ),
          ],
        ),
      ),
      body: _buildBody(),
      floatingActionButton: _isLoading || _errorMessage != null
          ? null
          : SizedBox(
              height: MediaQuery.of(context).size.height * 0.7,
              child: SingleChildScrollView(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Zoom In
                    FloatingActionButton(
                      heroTag: 'zoom_in',
                      mini: true,
                      onPressed: _zoomIn,
                      tooltip: 'Zoom In',
                      child: const Icon(Icons.zoom_in),
                    ),
                    const SizedBox(height: 8),
                    // Zoom Out
                    FloatingActionButton(
                      heroTag: 'zoom_out',
                      mini: true,
                      onPressed: _zoomOut,
                      tooltip: 'Zoom Out',
                      child: const Icon(Icons.zoom_out),
                    ),
                    const SizedBox(height: 16),
                    // Transpose Up
                    FloatingActionButton(
                      heroTag: 'transpose_up',
                      mini: true,
                      onPressed: _transposeUp,
                      tooltip: 'Transpose Up',
                      child: const Icon(Icons.arrow_upward),
                    ),
                    const SizedBox(height: 8),
                    // Transpose Down
                    FloatingActionButton(
                      heroTag: 'transpose_down',
                      mini: true,
                      onPressed: _transposeDown,
                      tooltip: 'Transpose Down',
                      child: const Icon(Icons.arrow_downward),
                    ),
                    const SizedBox(height: 8),
                    // Reset Transpose
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
    );
  }

  Widget _buildBody() {
    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Icon(
                Icons.error_outline,
                color: Colors.red,
                size: 48,
              ),
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
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return WebViewWidget(controller: _controller!);
  }
}
