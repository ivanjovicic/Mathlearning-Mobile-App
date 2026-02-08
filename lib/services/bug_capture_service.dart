import 'dart:convert';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart';
import 'package:flutter/widgets.dart';

class BugCaptureService {
  BugCaptureService._();
  static final BugCaptureService instance = BugCaptureService._();

  final GlobalKey rootBoundaryKey = GlobalKey(debugLabel: 'bug_capture_root');

  Future<String?> captureScreenshotBase64() async {
    try {
      final currentContext = rootBoundaryKey.currentContext;
      if (currentContext == null) {
        return null;
      }
      final renderObject = currentContext.findRenderObject();
      if (renderObject is! RenderRepaintBoundary) {
        return null;
      }
      final image = await renderObject.toImage(pixelRatio: 1.25);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) {
        return null;
      }
      final bytes = byteData.buffer.asUint8List();
      return base64Encode(bytes);
    } catch (_) {
      return null;
    }
  }
}
