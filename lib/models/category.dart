import 'package:flutter/material.dart';

class Category {
  final int? id;
  final String name;
  final String description;
  final int iconCode; // IconData.codePoint
  final int colorValue; // Color.value
  final String? businessRuc; // ← NUEVO: v12
  final bool isActive;

  Category({
    this.id,
    required this.name,
    this.description = '',
    this.iconCode = 0xe148, // Icons.category code
    this.colorValue = 0xFF7209B7, // primaryLilac value
    this.businessRuc,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'iconCode': iconCode,
      'colorValue': colorValue,
      'businessRuc': businessRuc,
      'isActive': isActive ? 1 : 0,
    };
  }

  factory Category.fromMap(Map<String, dynamic> map) {
    return Category(
      id: map['id'],
      name: map['name'],
      description: map['description'] ?? '',
      iconCode: map['iconCode'] ?? 0xe148,
      colorValue: map['colorValue'] ?? 0xFF7209B7,
      businessRuc: map['businessRuc'],
      isActive: map['isActive'] == 1,
    );
  }

  IconData get icon => IconData(iconCode, fontFamily: 'MaterialIcons');
  Color get color => Color(colorValue);

  Category copyWith({
    int? id,
    String? name,
    String? description,
    int? iconCode,
    int? colorValue,
    String? businessRuc,
    bool? isActive,
  }) {
    return Category(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      iconCode: iconCode ?? this.iconCode,
      colorValue: colorValue ?? this.colorValue,
      businessRuc: businessRuc ?? this.businessRuc,
      isActive: isActive ?? this.isActive,
    );
  }
}
