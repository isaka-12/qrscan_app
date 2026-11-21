import 'package:material_ui/material_ui.dart';

export '../../../../core/utils/date_labels.dart';

/// What a scanned code contains, with an icon, color and a human title
/// ("github.com", "Wi-Fi · HomeNet", a contact's name) for lists.
class ScanKind {
  final IconData icon;
  final Color color;
  final String label;
  final String title;

  const ScanKind(this.icon, this.color, this.label, this.title);

  static const _blue = Color(0xFF1E88E5);
  static const _green = Color(0xFF43A047);
  static const _purple = Color(0xFF8E24AA);
  static const _teal = Color(0xFF00897B);
  static const _cyan = Color(0xFF00ACC1);
  static const _red = Color(0xFFE53935);
  static const _orange = Color(0xFFF4511E);
  static const _grey = Color(0xFF757575);

  static final _email = RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$');
  static final _phone = RegExp(r'^\+?[0-9 ()\-]{7,}$');

  static ScanKind of(String raw) {
    final d = raw.trim();
    final lower = d.toLowerCase();

    if (lower.startsWith('wifi:')) {
      final ssid = RegExp(r'S:((?:\\.|[^;])*)').firstMatch(d)?.group(1);
      final name = ssid?.replaceAllMapped(RegExp(r'\\(.)'), (m) => m[1]!);
      return ScanKind(
        Icons.wifi,
        _green,
        'Wi-Fi',
        (name == null || name.isEmpty) ? 'Wi-Fi network' : name,
      );
    }
    if (lower.startsWith('begin:vcard')) {
      final fn = RegExp(
        r'^FN:(.*)$',
        multiLine: true,
        caseSensitive: false,
      ).firstMatch(d)?.group(1)?.trim();
      return ScanKind(
        Icons.person_outline,
        _purple,
        'Contact',
        (fn == null || fn.isEmpty) ? 'Contact card' : fn.replaceAll(r'\,', ','),
      );
    }
    if (lower.startsWith('tel:')) {
      return ScanKind(Icons.phone_outlined, _teal, 'Phone', d.substring(4));
    }
    if (lower.startsWith('smsto:') || lower.startsWith('sms:')) {
      final rest = d.substring(d.indexOf(':') + 1);
      final number = rest.split(':').first;
      return ScanKind(
        Icons.sms_outlined,
        _cyan,
        'SMS',
        number.isEmpty ? 'Text message' : number,
      );
    }
    if (lower.startsWith('mailto:')) {
      final to = d.substring(7).split('?').first;
      return ScanKind(
        Icons.email_outlined,
        _red,
        'Email',
        to.isEmpty ? 'Email' : Uri.decodeComponent(to),
      );
    }
    if (lower.startsWith('geo:')) {
      return ScanKind(
        Icons.place_outlined,
        _orange,
        'Location',
        d.substring(4).split('?').first,
      );
    }
    if (lower.startsWith('http://') || lower.startsWith('https://')) {
      final uri = Uri.tryParse(d);
      var host = uri?.host ?? d;
      if (host.startsWith('www.')) host = host.substring(4);
      final path = uri == null || uri.path == '/' ? '' : uri.path;
      final title = host.isEmpty ? d : '$host$path';
      return ScanKind(Icons.link, _blue, 'Website', title);
    }
    if (_email.hasMatch(d)) {
      return ScanKind(Icons.email_outlined, _red, 'Email', d);
    }
    if (_phone.hasMatch(d)) {
      return ScanKind(Icons.phone_outlined, _teal, 'Phone', d);
    }
    final firstLine = d.split('\n').first.trim();
    return ScanKind(
      Icons.notes,
      _grey,
      'Text',
      firstLine.isEmpty ? 'Empty code' : firstLine,
    );
  }
}
