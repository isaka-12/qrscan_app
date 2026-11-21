import 'dart:convert';

import 'entities/qr_type.dart';

/// Turns form values into the text stored inside a QR code, using the formats
/// that phone cameras and scanner apps recognise (tel:, mailto:, SMSTO:,
/// WIFI:, vCard).
class QrEncoder {
  QrEncoder._();

  /// Payload limit in UTF-8 bytes. A QR code at error-correction level M
  /// holds at most 2331 bytes; staying below keeps codes dense but scannable.
  static const int maxBytes = 2000;

  static String encode(QrType type, Map<String, String> values) {
    String v(String key) => (values[key] ?? '').trim();

    switch (type) {
      case QrType.text:
        return v('text');
      case QrType.url:
        return normalizeUrl(v('url'));
      case QrType.phone:
        return 'tel:${cleanPhone(v('phone'))}';
      case QrType.sms:
        return 'SMSTO:${cleanPhone(v('phone'))}:${v('message')}';
      case QrType.email:
        final params = <String>[
          if (v('subject').isNotEmpty)
            'subject=${Uri.encodeComponent(v('subject'))}',
          if (v('body').isNotEmpty) 'body=${Uri.encodeComponent(v('body'))}',
        ];
        return 'mailto:${v('to')}${params.isEmpty ? '' : '?${params.join('&')}'}';
      case QrType.wifi:
        final security = v('security').isEmpty ? 'WPA' : v('security');
        final b = StringBuffer('WIFI:T:$security;S:${_escapeWifi(v('ssid'))};');
        if (security != 'nopass') {
          // Passwords are not trimmed: spaces can be part of them.
          b.write('P:${_escapeWifi(values['password'] ?? '')};');
        }
        if (v('hidden') == 'true') b.write('H:true;');
        b.write(';');
        return b.toString();
      case QrType.contact:
        final first = v('firstName');
        final last = v('lastName');
        final lines = <String>[
          'BEGIN:VCARD',
          'VERSION:3.0',
          'N:${_escapeVcard(last)};${_escapeVcard(first)};;;',
          'FN:${_escapeVcard([first, last].where((s) => s.isNotEmpty).join(' '))}',
          if (v('organization').isNotEmpty)
            'ORG:${_escapeVcard(v('organization'))}',
          if (v('phone').isNotEmpty) 'TEL;TYPE=CELL:${cleanPhone(v('phone'))}',
          if (v('email').isNotEmpty) 'EMAIL:${_escapeVcard(v('email'))}',
          if (v('website').isNotEmpty)
            'URL:${_escapeVcard(normalizeUrl(v('website')))}',
          'END:VCARD',
        ];
        return lines.join('\n');
    }
  }

  /// Returns a message describing what is missing or wrong, or null when the
  /// values can be encoded.
  static String? validate(QrType type, Map<String, String> values) {
    String v(String key) => (values[key] ?? '').trim();

    for (final field in type.fields) {
      if (!field.required || field.isHidden(values)) continue;
      // Wi-Fi passwords may legitimately be only spaces; check untrimmed.
      final raw = field.kind == QrFieldKind.password
          ? (values[field.key] ?? '')
          : v(field.key);
      if (raw.isEmpty) return '${field.label} is required';
    }

    switch (type) {
      case QrType.url:
        if (!isValidUrl(v('url'))) return 'Enter a valid website address';
      case QrType.phone:
      case QrType.sms:
        if (!isValidPhone(v('phone'))) return 'Enter a valid phone number';
      case QrType.email:
        if (!isValidEmail(v('to'))) return 'Enter a valid email address';
      case QrType.wifi:
        if (v('security') == 'WPA' &&
            (values['password'] ?? '').isNotEmpty &&
            (values['password'] ?? '').length < 8) {
          return 'WPA passwords are at least 8 characters';
        }
      case QrType.contact:
        if (v('firstName').isEmpty && v('lastName').isEmpty) {
          return 'Enter a first or last name';
        }
        if (v('phone').isNotEmpty && !isValidPhone(v('phone'))) {
          return 'Enter a valid phone number';
        }
        if (v('email').isNotEmpty && !isValidEmail(v('email'))) {
          return 'Enter a valid email address';
        }
        if (v('website').isNotEmpty && !isValidUrl(v('website'))) {
          return 'Enter a valid website address';
        }
      case QrType.text:
        break;
    }

    if (utf8.encode(encode(type, values)).length > maxBytes) {
      return 'Too much content for one QR code — shorten it';
    }
    return null;
  }

  /// True when no field has been filled in yet, so the preview can show a
  /// hint instead of an error.
  static bool isEmpty(QrType type, Map<String, String> values) =>
      type.fields.every(
        (f) =>
            f.kind == QrFieldKind.choice ||
            f.kind == QrFieldKind.toggle ||
            (values[f.key] ?? '').trim().isEmpty,
      );

  /// A short, human-readable title for a saved code.
  static String summary(QrType type, Map<String, String> values) {
    String v(String key) => (values[key] ?? '').trim();
    final s = switch (type) {
      QrType.text => v('text').split('\n').first,
      QrType.url => v('url'),
      QrType.phone || QrType.sms => v('phone'),
      QrType.email => v('to'),
      QrType.wifi => v('ssid'),
      QrType.contact => [
        v('firstName'),
        v('lastName'),
      ].where((s) => s.isNotEmpty).join(' '),
    };
    return s.isEmpty ? type.label : s;
  }

  static String normalizeUrl(String url) {
    final u = url.trim();
    if (u.isEmpty || u.contains('://')) return u;
    return 'https://$u';
  }

  static bool isValidUrl(String url) {
    final uri = Uri.tryParse(normalizeUrl(url));
    if (uri == null || !uri.hasScheme || uri.host.isEmpty) return false;
    return uri.host.contains('.') || uri.host == 'localhost';
  }

  static String cleanPhone(String phone) {
    final t = phone.trim();
    final digits = t.replaceAll(RegExp(r'[^0-9]'), '');
    return t.startsWith('+') ? '+$digits' : digits;
  }

  static bool isValidPhone(String phone) {
    final digits = cleanPhone(phone).replaceAll('+', '');
    return digits.length >= 3 && digits.length <= 15;
  }

  static bool isValidEmail(String email) =>
      RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email.trim());

  // Wi-Fi QR format: \ ; , : " must be backslash-escaped.
  static String _escapeWifi(String s) =>
      s.replaceAllMapped(RegExp(r'([\\;,:"])'), (m) => '\\${m[1]}');

  // vCard 3.0 text values: escape \ , ; and newlines.
  static String _escapeVcard(String s) => s
      .replaceAll('\\', '\\\\')
      .replaceAll(',', '\\,')
      .replaceAll(';', '\\;')
      .replaceAll('\n', '\\n');
}
