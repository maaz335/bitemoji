import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';

/// Screen 1: The Avatar Creator (WebView)
/// Embeds Ready Player Me avatar creation flow using frameApi.
/// Automatically extracts the exported .glb URL and pops back to the caller.
class AvatarCreatorScreen extends StatefulWidget {
  const AvatarCreatorScreen({super.key});

  @override
  State<AvatarCreatorScreen> createState() => _AvatarCreatorScreenState();
}

class _AvatarCreatorScreenState extends State<AvatarCreatorScreen> {
  late final WebViewController _controller;
  bool _isLoading = true;
  double _loadingProgress = 0.0;
  bool _hasExported = false;

  static const String _rpmUrl = 'https://demo.readyplayer.me/avatar?frameApi';

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setBackgroundColor(const Color(0xFF0F172A))
      ..addJavaScriptChannel(
        'RPMChannel',
        onMessageReceived: (JavaScriptMessage message) {
          _handleRpmMessage(message.message);
        },
      )
      ..setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            if (mounted) {
              setState(() {
                _loadingProgress = progress / 100.0;
              });
            }
          },
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = true;
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
            _injectRpmEventListener();
          },
          onWebResourceError: (WebResourceError error) {
            debugPrint('RPM WebView Error: ${error.description}');
          },
        ),
      )
      ..loadRequest(Uri.parse(_rpmUrl));
  }

  /// Injects JS listener to bridge Ready Player Me window.postMessage events to RPMChannel
  void _injectRpmEventListener() {
    _controller.runJavaScript('''
      (function() {
        if (window.__rpmListenerInjected) return;
        window.__rpmListenerInjected = true;

        window.addEventListener('message', function(event) {
          try {
            var json = typeof event.data === 'string' ? JSON.parse(event.data) : event.data;
            if (json) {
              // Frame ready handshake: subscribe to all v1 events
              if (json.eventName === 'v1.frame.ready') {
                window.postMessage(
                  JSON.stringify({
                    target: 'readyplayerme',
                    type: 'subscribe',
                    eventName: 'v1.**'
                  }),
                  '*'
                );
              }

              // Listen for the avatar export event
              if (json.eventName === 'v1.avatar.exported' ||
                  (json.source === 'readyplayerme' && json.eventName === 'v1.avatar.exported')) {
                RPMChannel.postMessage(typeof event.data === 'string' ? event.data : JSON.stringify(event.data));
              }
            }
          } catch (e) {
            console.error('RPM JS Bridge Error:', e);
          }
        });
      })();
    ''');
  }

  /// Handles incoming JSON messages from RPMChannel and extracts the .glb URL
  void _handleRpmMessage(String rawMessage) {
    if (_hasExported) return;

    try {
      final dynamic decoded = jsonDecode(rawMessage);
      if (decoded is Map<String, dynamic>) {
        final eventName = decoded['eventName']?.toString();

        if (eventName == 'v1.avatar.exported') {
          String? glbUrl;
          final dynamic data = decoded['data'];

          if (data is Map<String, dynamic>) {
            glbUrl = data['url']?.toString();
          } else if (data is String) {
            glbUrl = data;
          } else if (decoded['url'] != null) {
            glbUrl = decoded['url']?.toString();
          }

          if (glbUrl != null && glbUrl.isNotEmpty) {
            _hasExported = true;
            if (mounted) {
              // Automatically pop navigation stack and return the .glb URL to caller
              Navigator.of(context).pop(glbUrl);
            }
          }
        }
      }
    } catch (e) {
      debugPrint('Error parsing RPM message: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Create 3D Avatar'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading)
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: LinearProgressIndicator(
                value: _loadingProgress > 0 ? _loadingProgress : null,
                color: const Color(0xFF6366F1),
                backgroundColor: const Color(0xFF1E293B),
              ),
            ),
        ],
      ),
    );
  }
}
