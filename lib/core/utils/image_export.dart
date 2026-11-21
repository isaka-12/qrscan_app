import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/widgets.dart' show GlobalKey;
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ImageExportException implements Exception {
  final String message;
  const ImageExportException(this.message);

  @override
  String toString() => message;
}

/// Renders an on-screen widget (QR code, photo post) to a PNG and saves or
/// shares it.
class ImageExport {
  ImageExport._();

  /// Captures the widget under [key] (a RepaintBoundary) as a PNG about
  /// [targetWidth] pixels wide: sharp enough for print and social posts.
  static Future<Uint8List> capture(
    GlobalKey key, {
    double targetWidth = 1080,
  }) async {
    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null || boundary.size.isEmpty) {
      throw const ImageExportException('The image isn\'t ready yet');
    }
    final image = await boundary.toImage(
      pixelRatio: targetWidth / boundary.size.width,
    );
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) {
        throw const ImageExportException('Could not render the image');
      }
      return bytes.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  static Future<void> saveToGallery(
    Uint8List png, {
    String prefix = 'locus',
  }) async {
    try {
      if (!await Gal.hasPermission() && !await Gal.requestPermission()) {
        throw const ImageExportException(
          'Allow photo access to save images to your gallery',
        );
      }
      await Gal.putImageBytes(png, name: _fileName(prefix));
    } on GalException catch (e) {
      throw ImageExportException(e.type.message);
    }
  }

  static Future<void> share(Uint8List png, {String prefix = 'locus'}) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${_fileName(prefix)}.png');
    await file.writeAsBytes(png, flush: true);
    // Only the image is shared (a QR's encoded text can hold a password).
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path, mimeType: 'image/png')]),
    );
  }

  /// Shares files that are already on disk (e.g. library photos).
  static Future<void> shareFiles(List<String> paths) async {
    if (paths.isEmpty) return;
    await SharePlus.instance.share(
      ShareParams(files: [for (final p in paths) XFile(p)]),
    );
  }

  static String _fileName(String prefix) =>
      '${prefix}_${DateTime.now().millisecondsSinceEpoch}';
}
