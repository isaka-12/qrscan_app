import 'qr_style.dart';
import 'qr_type.dart';

/// A QR code the user made and saved to "My codes".
class CreatedCode {
  final int? id;
  final QrType type;
  final Map<String, String> fields;
  final QrStyle style;

  /// The encoded text inside the QR code.
  final String data;
  final DateTime createdAt;
  final DateTime updatedAt;

  const CreatedCode({
    this.id,
    required this.type,
    required this.fields,
    required this.style,
    required this.data,
    required this.createdAt,
    required this.updatedAt,
  });

  CreatedCode copyWith({int? id, DateTime? updatedAt}) => CreatedCode(
    id: id ?? this.id,
    type: type,
    fields: fields,
    style: style,
    data: data,
    createdAt: createdAt,
    updatedAt: updatedAt ?? this.updatedAt,
  );
}
