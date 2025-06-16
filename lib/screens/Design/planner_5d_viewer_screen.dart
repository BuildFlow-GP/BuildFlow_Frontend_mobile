// screens/planner_5d_viewer_screen.dart
// import 'package:flutter/foundation.dart' show kIsWeb; //  لـ kIsWeb
import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:logger/logger.dart';

import '../../themes/app_colors.dart';

final Logger logger = Logger(printer: PrettyPrinter(methodCount: 1));

class Planner5DViewerScreen extends StatefulWidget {
  final String plannerUrl;

  const Planner5DViewerScreen({super.key, required this.plannerUrl});

  @override
  State<Planner5DViewerScreen> createState() => _Planner5DViewerScreenState();
}

class _Planner5DViewerScreenState extends State<Planner5DViewerScreen> {
  late final WebViewController _controller; //  استخدام late final
  // ignore: unused_field
  bool _isLoadingPage = true;
  String? _loadingError; //  لتخزين رسالة الخطأ إذا حدث

  @override
  void initState() {
    super.initState();
    logger.i("Planner5DViewerScreen received URL: '${widget.plannerUrl}'");

    Uri? uriToLoad;
    try {
      uriToLoad = Uri.parse(widget.plannerUrl);
      // ... (نفس التحقق من صلاحية uriToLoad) ...
      if (!uriToLoad.isAbsolute ||
          (uriToLoad.scheme != 'http' && uriToLoad.scheme != 'https')) {
        // ... (معالجة الخطأ كما كانت) ...
        _controller =
            WebViewController()..loadHtmlString(
              '<html><body><h1>Invalid URL</h1></body></html>',
            );
        return;
      }
    } catch (e) {
      // ... (معالجة الخطأ كما كانت) ...
      _controller =
          WebViewController()..loadHtmlString(
            '<html><body><h1>Error Parsing URL</h1></body></html>',
          );
      return;
    }

    //  ✅✅✅  أبسط تهيئة  ✅✅✅
    try {
      _controller = WebViewController(); //  إنشاء بدون أي إعدادات إضافية
      _controller.loadRequest(uriToLoad); //  ثم تحميل الطلب
      logger.i(
        "Simplified WebViewController initialized and loadRequest called.",
      );
    } catch (e, s) {
      logger.e(
        "Error with simplified WebViewController init or load",
        error: e,
        stackTrace: s,
      );
      _setErrorState("Failed to initialize WebView: ${e.toString()}");
    }
  }

  //  أبقي دالة _setErrorState كما هي
  void _setErrorState(String errorMessage) {
    if (mounted) {
      setState(() {
        _isLoadingPage = false;
        _loadingError = errorMessage;
      });
    }
  }

  // ignore: unused_element
  Future<void> _tryLoadRequest(Uri uri) async {
    try {
      logger.i("Attempting to load request: $uri");
      await _controller.loadRequest(uri); //  استخدام await هنا
      logger.i("loadRequest called successfully for: $uri");
    } catch (e, s) {
      logger.e(
        "Error in _controller.loadRequest for URI '$uri'",
        error: e,
        stackTrace: s,
      );
      if (mounted) {
        _setErrorState("Failed to load 3D view: ${e.toString()}");
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('3D Project View'),
        backgroundColor: AppColors.accent,

        actions: [
          // IconButton(
          //   icon: const Icon(Icons.arrow_back_ios),
          //   onPressed: () async {
          //     if (await _controller.canGoBack()) {
          //       await _controller.goBack();
          //     } else if (Navigator.canPop(context)) {
          //       Navigator.pop(context);
          //     }
          //   },
          // ),
          // IconButton(
          //   icon: const Icon(Icons.arrow_forward_ios),
          //   onPressed: () async {
          //     if (await _controller.canGoForward()) {
          //       await _controller.goForward();
          //     }
          //   },
          // ),
          IconButton(
            icon: const Icon(Icons.replay),
            onPressed: () => _controller.reload(),
          ),
        ],
      ),
      body: Stack(
        children: [
          if (_loadingError ==
              null) //  فقط اعرض الـ WebView إذا لم يكن هناك خطأ في تهيئة الـ URL
            // تأكدي أن _controller تم تهيئته قبل استخدامه
            // يمكن استخدام late final _controller أو التحقق من null
            // إذا كان _controller لا يزال غير مهيأ بسبب خطأ في initState، هذا قد يسبب مشكلة
            // ولكن _setErrorState يجب أن يمنع هذا
            WebViewWidget(controller: _controller),
          //  if (_isLoadingPage) const Center(child: CircularProgressIndicator()),
          if (_loadingError != null)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  "Error: $_loadingError",
                  style: const TextStyle(color: Colors.red),
                  textAlign: TextAlign.center,
                ),
              ),
            ),
        ],
      ),
    );
  }
}
