// The kinds of QR codes the QR maker can create, and the form fields each needs.

enum QrFieldKind {
  text,
  multiline,
  url,
  phone,
  email,
  password,
  choice,
  toggle,
}

class QrField {
  final String key;
  final String label;
  final String? hint;
  final QrFieldKind kind;
  final bool required;

  /// For [QrFieldKind.choice]: value -> label, in display order.
  final Map<String, String> choices;

  /// Initial value for choice/toggle fields.
  final String? defaultValue;

  /// Hide this field while another field has the given value,
  /// e.g. the Wi-Fi password while security is "nopass".
  final MapEntry<String, String>? hiddenWhen;

  const QrField({
    required this.key,
    required this.label,
    this.hint,
    this.kind = QrFieldKind.text,
    this.required = false,
    this.choices = const {},
    this.defaultValue,
    this.hiddenWhen,
  });

  bool isHidden(Map<String, String> values) =>
      hiddenWhen != null && values[hiddenWhen!.key] == hiddenWhen!.value;
}

enum QrType {
  url('Website', [
    QrField(
      key: 'url',
      label: 'Website address',
      hint: 'example.com',
      kind: QrFieldKind.url,
      required: true,
    ),
  ]),
  text('Text', [
    QrField(
      key: 'text',
      label: 'Text',
      hint: 'Any message or note',
      kind: QrFieldKind.multiline,
      required: true,
    ),
  ]),
  wifi('Wi-Fi', [
    QrField(key: 'ssid', label: 'Network name (SSID)', required: true),
    QrField(
      key: 'security',
      label: 'Security',
      kind: QrFieldKind.choice,
      choices: {'WPA': 'WPA/WPA2/WPA3', 'WEP': 'WEP', 'nopass': 'None'},
      defaultValue: 'WPA',
    ),
    QrField(
      key: 'password',
      label: 'Password',
      kind: QrFieldKind.password,
      required: true,
      hiddenWhen: MapEntry('security', 'nopass'),
    ),
    QrField(
      key: 'hidden',
      label: 'Hidden network',
      kind: QrFieldKind.toggle,
      defaultValue: 'false',
    ),
  ]),
  contact('Contact', [
    QrField(key: 'firstName', label: 'First name'),
    QrField(key: 'lastName', label: 'Last name'),
    QrField(key: 'phone', label: 'Phone', kind: QrFieldKind.phone),
    QrField(key: 'email', label: 'Email', kind: QrFieldKind.email),
    QrField(key: 'organization', label: 'Company'),
    QrField(key: 'website', label: 'Website', kind: QrFieldKind.url),
  ]),
  phone('Phone', [
    QrField(
      key: 'phone',
      label: 'Phone number',
      hint: '+255 712 345 678',
      kind: QrFieldKind.phone,
      required: true,
    ),
  ]),
  sms('SMS', [
    QrField(
      key: 'phone',
      label: 'Phone number',
      kind: QrFieldKind.phone,
      required: true,
    ),
    QrField(key: 'message', label: 'Message', kind: QrFieldKind.multiline),
  ]),
  email('Email', [
    QrField(
      key: 'to',
      label: 'Email address',
      kind: QrFieldKind.email,
      required: true,
    ),
    QrField(key: 'subject', label: 'Subject'),
    QrField(key: 'body', label: 'Message', kind: QrFieldKind.multiline),
  ]);

  const QrType(this.label, this.fields);

  final String label;
  final List<QrField> fields;

  static QrType fromName(String name) => QrType.values.firstWhere(
    (t) => t.name == name,
    orElse: () => QrType.text,
  );

  /// Field values a fresh form starts with.
  Map<String, String> get initialValues => {
    for (final f in fields) f.key: f.defaultValue ?? '',
  };
}
