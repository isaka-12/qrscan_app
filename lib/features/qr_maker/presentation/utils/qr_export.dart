import 'dart:io';
import 'dart:typed_data';
import 'dart:ui' as ui;

import 'package:flutter/rendering.dart' show RenderRepaintBoundary;
import 'package:flutter/widgets.dart' show GlobalKey;
import 'package:gal/gal.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class QrExportException implements Exception {
  final String message;
  const QrExportException(this.message);

  @override
  String toString() => message;
}

/// Renders the on-screen QR preview to a PNG and saves or shares it.
class QrExport {
  QrExport._();

  /// Captures the widget under [key] (a RepaintBoundary) as a PNG about
  /// [targetWidth] pixels wide: sharp enough for print and social posts.
  static Future<Uint8List> capture(
    GlobalKey key, {
    double targetWidth = 1080,
  }) async {
    final boundary =
        key.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null || boundary.size.isEmpty) {
      throw const QrExportException('The QR code isn\'t ready yet');
    }
    final image = await boundary.toImage(
      pixelRatio: targetWidth / boundary.size.width,
    );
    try {
      final bytes = await image.toByteData(format: ui.ImageByteFormat.png);
      if (bytes == null) {
        throw const QrExportException('Could not render the QR code');
      }
      return bytes.buffer.asUint8List();
    } finally {
      image.dispose();
    }
  }

  static Future<void> saveToGallery(Uint8List png) async {
    try {
      if (!await Gal.hasPermission() && !await Gal.requestPermission()) {
        throw const QrExportException(
          'Allow photo access to save QR codes to your gallery',
        );
      }
      await Gal.putImageBytes(png, name: _fileName());
    } on GalException catch (e) {
      throw QrExportException(e.type.message);
    }
  }

  static Future<void> share(Uint8List png) async {
    final dir = await getTemporaryDirectory();
    final file = File('${dir.path}/${_fileName()}.png');
    await file.writeAsBytes(png, flush: true);
    // Only the image is shared: the encoded text can hold a Wi-Fi password.
    await SharePlus.instance.share(
      ShareParams(files: [XFile(file.path, mimeType: 'image/png')]),
    );
  }

  static String _fileName() =>
      'locus_qr_${DateTime.now().millisecondsSinceEpoch}';
}
