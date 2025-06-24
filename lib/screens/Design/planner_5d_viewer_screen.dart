// screens/Design/planner_5d_viewer_screen.dart
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:logger/logger.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart'; // ✅

import '../../themes/app_colors.dart';

final Logger logger = Logger(
  printer: PrettyPrinter(methodCount: 1, errorMethodCount: 5),
);

class Planner5DViewerScreen extends StatefulWidget {
  final String plannerUrl;
  const Planner5DViewerScreen({super.key, required this.plannerUrl});

  @override
  State<Planner5DViewerScreen> createState() => _Planner5DViewerScreenState();
}

class _Planner5DViewerScreenState extends State<Planner5DViewerScreen> {
  WebViewController? _controller;
  bool _isLoadingPage = true;
  String? _loadingError;

  @override
  void initState() {
    super.initState();
    logger.i("Planner5DViewerScreen received URL: '${widget.plannerUrl}'");
    _initializeWebView();
  }

  Future<void> _initializeWebView() async {
    Uri? uriToLoad;
    try {
      uriToLoad = Uri.parse(widget.plannerUrl);
      if (!uriToLoad.isAbsolute ||
          (uriToLoad.scheme != 'http' && uriToLoad.scheme != 'https')) {
        final errorMsg = "Invalid URL format. URL: $uriToLoad";
        _setErrorStateAndPop(errorMsg);
        return;
      }
    } catch (e) {
      final errorMsg = "Error parsing URL '${widget.plannerUrl}'";
      _setErrorStateAndPop("$errorMsg: $e");
      return;
    }

    // --- إنشاء Controller ---
    //  في الإصدارات التي نستهدفها، قد لا نحتاج لـ PlatformWebViewControllerCreationParams إذا لم نمرر شيئاً خاصاً بالمنصة عند الإنشاء
    // final WebViewController controller = WebViewController();
    //  ولكن للاحتياط، لنبقِها كما هي
    late final PlatformWebViewControllerCreationParams params;
    if (WebViewPlatform.instance is AndroidWebViewPlatform) {
      params = AndroidWebViewControllerCreationParams();
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }
    final WebViewController controller =
        WebViewController.fromPlatformCreationParams(params);

    try {
      // --- الإعدادات العامة ---
      await controller.setJavaScriptMode(JavaScriptMode.unrestricted);
      await controller.setBackgroundColor(const Color(0x00000000));
      await controller.setNavigationDelegate(
        NavigationDelegate(
          onProgress: (int progress) {
            /* ... */
          },
          onPageStarted: (String url) {
            if (mounted) {
              setState(() {
                _isLoadingPage = true;
                _loadingError = null;
              });
            }
          },
          onPageFinished: (String url) {
            if (mounted) setState(() => _isLoadingPage = false);
          },
          onWebResourceError: (WebResourceError error) {
            /* ... */
          },
        ),
      );

      // --- ✅✅✅ تم تعليق كل إعدادات Android الخاصة مؤقتاً ✅✅✅ ---
      // final platformController = controller.platform;
      // if (platformController is AndroidWebViewController) {
      //   logger.i("Platform is AndroidWebViewController. Attempting Android settings...");
      //   await AndroidWebViewController.enableDebugging(true);
      //   try {
      //     // platformController.setDomStorageEnabled(true);
      //     // platformController.setJavaScriptCanOpenWindowsAutomatically(true);
      //     // platformController.setLoadWithOverviewMode(true);
      //     // platformController.setUseWideViewPort(true);
      //     // platformController.setMediaPlaybackRequiresUserGesture(false);
      //     logger.i("Android Specific Settings temporarily skipped for debugging.");
      //   } catch (e, s) {
      //     logger.e("Error applying Android settings (even if skipped)", error: e, stackTrace:s);
      //   }
      // } else {
      //   logger.w("Platform controller is not Android or null: ${controller.platform.runtimeType}");
      // }
      // --- نهاية تعليق إعدادات Android ---

      if (mounted) {
        setState(() {
          _controller = controller;
        });
      }

      if (_controller != null) {
        await _tryLoadRequest(uriToLoad);
      } else {
        /* ... معالجة الخطأ ... */
      }
    } catch (e, s) {
      logger.e(
        "Error during WebView initialization or first load",
        error: e,
        stackTrace: s,
      );
      _setErrorState("WebView Initialization Error: ${e.toString()}");
    }
  }

  void _setErrorStateAndPop(String errorMessage) {
    logger.e("Planner5DViewerScreen Fatal Error: $errorMessage");
    if (mounted) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          // تحقق إضافي
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                errorMessage,
                style: const TextStyle(color: Colors.white),
              ),
              backgroundColor: Colors.red,
            ),
          );
          Future.delayed(const Duration(milliseconds: 1500), () {
            if (mounted && Navigator.canPop(context)) {
              Navigator.of(context).pop();
            }
          });
        }
      });
      setState(() {
        _isLoadingPage = false;
        _loadingError = errorMessage;
      });
    }
  }

  void _setErrorState(String errorMessage) {
    if (mounted) {
      setState(() {
        _isLoadingPage = false;
        _loadingError = errorMessage;
      });
    }
  }

  Future<void> _tryLoadRequest(Uri uri) async {
    if (_controller == null) {
      _setErrorState("WebView controller not ready to load request.");
      return;
    }
    try {
      logger.i("Attempting to load request: $uri into WebView");
      await _controller!.loadRequest(uri);
      logger.i("WebView loadRequest called successfully for: $uri");
    } catch (e, s) {
      logger.e(
        "Error in _controller.loadRequest for URI '$uri'",
        error: e,
        stackTrace: s,
      );
      if (mounted) _setErrorState("Failed to load 3D view: ${e.toString()}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('3D Project View'),
        backgroundColor: AppColors.accent,
        actions: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios_new_rounded),
            tooltip: "Go Back",
            onPressed: () async {
              if (_controller == null) return;
              if (await _controller!.canGoBack()) {
                await _controller!.goBack();
              } else if (mounted && Navigator.canPop(context))
                Navigator.pop(context);
            },
          ),
          IconButton(
            icon: const Icon(Icons.arrow_forward_ios_rounded),
            tooltip: "Go Forward",
            onPressed: () async {
              if (_controller == null) return;
              if (await _controller!.canGoForward()) {
                await _controller!.goForward();
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: "Reload Page",
            onPressed: () {
              if (_controller == null) return;
              _controller!.reload();
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_loadingError == null &&
              _controller != null) //  ✅ تحقق من تهيئة الـ controller
            WebViewWidget(controller: _controller!) //  استخدام ! آمن
          else if (_loadingError != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const Icon(
                      Icons.error_outline_rounded,
                      color: Colors.red,
                      size: 50,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      _loadingError!,
                      style: const TextStyle(color: Colors.red, fontSize: 16),
                      textAlign: TextAlign.center,
                    ),
                  ],
                ),
              ),
            )
          else //  حالة تحميل أولية قبل تهيئة الـ controller بالكامل
            const Center(
              child: CircularProgressIndicator(
                key: ValueKey('init_loading_webview'),
              ),
            ),

          if (_isLoadingPage && _loadingError == null && _controller != null)
            const Center(
              child: CircularProgressIndicator(
                key: ValueKey('page_loading_webview'),
              ),
            ),
        ],
      ),
    );
  }
}
