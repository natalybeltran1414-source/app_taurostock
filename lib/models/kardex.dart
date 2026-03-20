class KardexMovement {
  final int? id;
  final int productId;
  final String productName;
  final DateTime date;
  final String type; // 'entrada', 'salida', 'ajuste'
  final String description;
  final int quantity;
  final int previousStock;
  final int newStock;
  final int? userId;
  final String? businessRuc; // ← NUEVO: v12

  KardexMovement({
    this.id,
    required this.productId,
    required this.productName,
    required this.date,
    required this.type,
    required this.description,
    required this.quantity,
    required this.previousStock,
    required this.newStock,
    this.userId,
    this.businessRuc,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'productId': productId,
      'productName': productName,
      'date': date.toIso8601String(),
      'type': type,
      'description': description,
      'quantity': quantity,
      'previousStock': previousStock,
      'newStock': newStock,
      'userId': userId,
      'businessRuc': businessRuc,
    };
  }

  factory KardexMovement.fromMap(Map<String, dynamic> map) {
    return KardexMovement(
      id: map['id'],
      productId: map['productId'],
      productName: map['productName'] ?? '',
      date: DateTime.parse(map['date']),
      type: map['type'],
      description: map['description'] ?? '',
      quantity: map['quantity'],
      previousStock: map['previousStock'],
      newStock: map['newStock'],
      userId: map['userId'],
      businessRuc: map['businessRuc'],
    );
  }
}
