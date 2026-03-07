import 'package:flutter/material.dart';

class Transaction {
  final int? id;
  final String description;
  final double amount;
  final String type; // 'ingreso' o 'gasto'
  final String category; // 'alquiler', 'servicios', 'sueldos', 'otros'
  final DateTime date;
  final String? notes;
  final bool isActive;

  Transaction({
    this.id,
    required this.description,
    required this.amount,
    required this.type,
    required this.category,
    required this.date,
    this.notes,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'description': description,
      'amount': amount,
      'type': type,
      'category': category,
      'date': date.toIso8601String(),
      'notes': notes,
      'isActive': isActive ? 1 : 0,
    };
  }

  factory Transaction.fromMap(Map<String, dynamic> map) {
    return Transaction(
      id: map['id'],
      description: map['description'],
      amount: map['amount']?.toDouble() ?? 0.0,
      type: map['type'] ?? 'gasto',
      category: map['category'] ?? 'otros',
      date: DateTime.parse(map['date']),
      notes: map['notes'],
      isActive: map['isActive'] == 1,
    );
  }

  Transaction copyWith({
    int? id,
    String? description,
    double? amount,
    String? type,
    String? category,
    DateTime? date,
    String? notes,
    bool? isActive,
  }) {
    return Transaction(
      id: id ?? this.id,
      description: description ?? this.description,
      amount: amount ?? this.amount,
      type: type ?? this.type,
      category: category ?? this.category,
      date: date ?? this.date,
      notes: notes ?? this.notes,
      isActive: isActive ?? this.isActive,
    );
  }

  // Getter para color según tipo
  Color get color => type == 'ingreso' ? Colors.green : Colors.red;
  
  // Getter para ícono según tipo
  IconData get icon => type == 'ingreso' 
      ? Icons.arrow_upward 
      : Icons.arrow_downward;
}