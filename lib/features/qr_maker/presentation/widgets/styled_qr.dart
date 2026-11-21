import 'package:material_ui/material_ui.dart';
import 'package:qr_flutter/qr_flutter.dart';

import '../../domain/entities/qr_style.dart';
import '../../domain/entities/qr_type.dart';

/// A QR code drawn with the user's style, with a quiet-zone margin and an
/// optional caption. This exact widget is what gets exported as an image.
class StyledQr extends StatelessWidget {
  final String data;
  final QrStyle style;
  final double size;
  final bool showCaption;

  const StyledQr({
    super.key,
    required this.data,
    required this.style,
    this.size = 220,
    this.showCaption = true,
  });

  @override
  Widget build(BuildContext context) {
    final fg = Color(style.foreground);
    final bg = Color(style.background);
    final hasCaption = showCaption && style.caption.trim().isNotEmpty;

    return Container(
      color: bg,
      // Scanners need a blank margin ("quiet zone") around the code.
      padding: EdgeInsets.all(size * 0.1),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          QrImageView(
            data: data,
            size: size,
            padding: EdgeInsets.zero,
            backgroundColor: bg,
            errorCorrectionLevel: QrErrorCorrectLevel.M,
            gapless: true,
            semanticsLabel: 'QR code',
            eyeStyle: QrEyeStyle(
              eyeShape: style.roundEyes ? QrEyeShape.circle : QrEyeShape.square,
              color: fg,
            ),
            dataModuleStyle: QrDataModuleStyle(
              dataModuleShape: style.roundDots
                  ? QrDataModuleShape.circle
                  : QrDataModuleShape.square,
              color: fg,
            ),
            errorStateBuilder: (context, error) => SizedBox.square(
              dimension: size,
              child: Center(
                child: Text(
                  'Too much content for one QR code',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: fg),
                ),
              ),
            ),
          ),
          if (hasCaption)
            Padding(
              padding: EdgeInsets.only(top: size * 0.06),
              child: SizedBox(
                width: size,
                child: Text(
                  style.caption.trim(),
                  textAlign: TextAlign.center,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: fg,
                    fontSize: size * 0.075,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

extension QrTypeIcon on QrType {
  IconData get icon => switch (this) {
    QrType.url => Icons.link,
    QrType.text => Icons.notes,
    QrType.wifi => Icons.wifi,
    QrType.contact => Icons.person_outline,
    QrType.phone => Icons.phone_outlined,
    QrType.sms => Icons.sms_outlined,
    QrType.email => Icons.email_outlined,
  };
}
