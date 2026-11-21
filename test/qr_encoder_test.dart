import 'package:flutter_test/flutter_test.dart';
import 'package:qrscan_app/features/qr_maker/data/models/created_code_model.dart';
import 'package:qrscan_app/features/qr_maker/domain/entities/qr_style.dart';
import 'package:qrscan_app/features/qr_maker/domain/entities/qr_type.dart';
import 'package:qrscan_app/features/qr_maker/domain/qr_encoder.dart';

Map<String, String> vals(QrType t, Map<String, String> v) => {
  ...t.initialValues,
  ...v,
};

void main() {
  group('encode', () {
    test('url gets https:// when no scheme', () {
      expect(QrEncoder.encode(QrType.url, {'url': ' example.com/a '}),
          'https://example.com/a');
      expect(QrEncoder.encode(QrType.url, {'url': 'http://x.org'}),
          'http://x.org');
    });

    test('phone keeps leading + and digits only', () {
      expect(QrEncoder.encode(QrType.phone, {'phone': '+255 (712) 345-678'}),
          'tel:+255712345678');
    });

    test('sms uses SMSTO format', () {
      expect(
        QrEncoder.encode(QrType.sms, {'phone': '0712 345678', 'message': 'Hi there'}),
        'SMSTO:0712345678:Hi there',
      );
    });

    test('email percent-encodes subject and body', () {
      expect(
        QrEncoder.encode(QrType.email, {
          'to': 'a@b.co',
          'subject': 'Hello & welcome',
          'body': '',
        }),
        'mailto:a@b.co?subject=Hello%20%26%20welcome',
      );
      expect(QrEncoder.encode(QrType.email, {'to': 'a@b.co'}), 'mailto:a@b.co');
    });

    test('wifi escapes special characters and keeps password spaces', () {
      expect(
        QrEncoder.encode(
          QrType.wifi,
          vals(QrType.wifi, {'ssid': 'Cafe;1', 'password': ' p:a"ss '}),
        ),
        r'WIFI:T:WPA;S:Cafe\;1;P: p\:a\"ss ;;',
      );
    });

    test('open wifi omits the password; hidden adds H:true', () {
      expect(
        QrEncoder.encode(
          QrType.wifi,
          vals(QrType.wifi, {
            'ssid': 'Guest',
            'security': 'nopass',
            'password': 'ignored',
            'hidden': 'true',
          }),
        ),
        'WIFI:T:nopass;S:Guest;H:true;;',
      );
    });

    test('contact builds an escaped vCard', () {
      final card = QrEncoder.encode(QrType.contact, {
        'firstName': 'Asha',
        'lastName': 'Juma',
        'organization': 'Locus, Ltd',
        'phone': '+255 712 000 111',
        'website': 'locus.example',
      });
      expect(card.split('\n'), [
        'BEGIN:VCARD',
        'VERSION:3.0',
        'N:Juma;Asha;;;',
        'FN:Asha Juma',
        r'ORG:Locus\, Ltd',
        'TEL;TYPE=CELL:+255712000111',
        'URL:https://locus.example',
        'END:VCARD',
      ]);
    });
  });

  group('validate', () {
    test('required fields', () {
      expect(QrEncoder.validate(QrType.url, {'url': ''}),
          'Website address is required');
      expect(QrEncoder.validate(QrType.wifi, vals(QrType.wifi, {'ssid': 'Home'})),
          'Password is required');
      // Password not needed for open networks.
      expect(
        QrEncoder.validate(
          QrType.wifi,
          vals(QrType.wifi, {'ssid': 'Home', 'security': 'nopass'}),
        ),
        isNull,
      );
    });

    test('format checks', () {
      expect(QrEncoder.validate(QrType.url, {'url': 'not a url'}), isNotNull);
      expect(QrEncoder.validate(QrType.url, {'url': 'example.com'}), isNull);
      expect(QrEncoder.validate(QrType.email, {'to': 'nope'}), isNotNull);
      expect(QrEncoder.validate(QrType.phone, {'phone': '12'}), isNotNull);
      expect(
        QrEncoder.validate(
          QrType.wifi,
          vals(QrType.wifi, {'ssid': 'Home', 'password': 'short'}),
        ),
        'WPA passwords are at least 8 characters',
      );
      expect(QrEncoder.validate(QrType.contact, {'phone': '0712345678'}),
          'Enter a first or last name');
    });

    test('rejects content too large for one QR code', () {
      expect(
        QrEncoder.validate(QrType.text, {'text': 'x' * (QrEncoder.maxBytes + 1)}),
        isNotNull,
      );
    });

    test('isEmpty ignores choice and toggle defaults', () {
      expect(QrEncoder.isEmpty(QrType.wifi, QrType.wifi.initialValues), isTrue);
      expect(
        QrEncoder.isEmpty(QrType.wifi, vals(QrType.wifi, {'ssid': 'a'})),
        isFalse,
      );
    });
  });

  test('summary', () {
    expect(QrEncoder.summary(QrType.wifi, {'ssid': 'Home'}), 'Home');
    expect(QrEncoder.summary(QrType.text, {'text': 'line1\nline2'}), 'line1');
    expect(QrEncoder.summary(QrType.contact, {}), 'Contact');
  });

  group('QrStyle.scanWarning', () {
    test('default black on white is fine', () {
      expect(const QrStyle().scanWarning, isNull);
    });
    test('inverted colors warn', () {
      expect(
        const QrStyle(foreground: 0xFFFFFFFF, background: 0xFF000000).scanWarning,
        contains('inverted'),
      );
    });
    test('low contrast warns', () {
      expect(
        const QrStyle(foreground: 0xFFF3742D, background: 0xFFFFF3E0).scanWarning,
        contains('Low contrast'),
      );
    });
  });

  test('CreatedCodeModel round-trips through a database row', () {
    final model = CreatedCodeModel(
      id: 7,
      type: QrType.wifi,
      fields: vals(QrType.wifi, {'ssid': 'Home', 'password': 'secret123'}),
      style: const QrStyle(roundDots: true, caption: 'Scan me'),
      data: 'WIFI:...',
      createdAt: DateTime.utc(2026, 11, 21, 10),
      updatedAt: DateTime.utc(2026, 11, 21, 11),
    );
    final back = CreatedCodeModel.fromMap(model.toMap());
    expect(back.id, 7);
    expect(back.type, QrType.wifi);
    expect(back.fields, model.fields);
    expect(back.style.toJson(), model.style.toJson());
    expect(back.updatedAt, model.updatedAt);
  });
}
