import 'dart:convert';

import '../../domain/entities/created_code.dart';
import '../../domain/entities/qr_style.dart';
import '../../domain/entities/qr_type.dart';

class CreatedCodeModel extends CreatedCode {
  const CreatedCodeModel({
    super.id,
    required super.type,
    required super.fields,
    required super.style,
    required super.data,
    required super.createdAt,
    required super.updatedAt,
  });

  factory CreatedCodeModel.fromEntity(CreatedCode c) => CreatedCodeModel(
    id: c.id,
    type: c.type,
    fields: c.fields,
    style: c.style,
    data: c.data,
    createdAt: c.createdAt,
    updatedAt: c.updatedAt,
  );

  factory CreatedCodeModel.fromMap(Map<String, dynamic> map) =>
      CreatedCodeModel(
        id: map['id'] as int?,
        type: QrType.fromName(map['type'] as String),
        fields: (jsonDecode(map['fields'] as String) as Map<String, dynamic>)
            .map((k, v) => MapEntry(k, v.toString())),
        style: QrStyle.fromJson(
          jsonDecode(map['style'] as String) as Map<String, dynamic>,
        ),
        data: map['data'] as String,
        createdAt: DateTime.parse(map['created_at'] as String),
        updatedAt: DateTime.parse(map['updated_at'] as String),
      );

  Map<String, dynamic> toMap() => {
    'id': id,
    'type': type.name,
    'fields': jsonEncode(fields),
    'style': jsonEncode(style.toJson()),
    'data': data,
    'created_at': createdAt.toIso8601String(),
    'updated_at': updatedAt.toIso8601String(),
  };
}
