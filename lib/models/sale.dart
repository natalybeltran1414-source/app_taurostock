class Sale {
  final int? id;
  final int clientId;
  final double total;
  final double discount;
  final double finalAmount;
  final String paymentMethod; // 'efectivo', 'credito', 'transferencia'
  final DateTime saleDate;
  final List<SaleItem> items;
  final String status; // 'completada', 'pendiente'
  final String? notes;

  Sale({
    this.id,
    required this.clientId,
    required this.total,
    this.discount = 0,
    required this.finalAmount,
    required this.paymentMethod,
    required this.saleDate,
    required this.items,
    this.status = 'completada',
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'clientId': clientId,
      'total': total,
      'discount': discount,
      'finalAmount': finalAmount,
      'paymentMethod': paymentMethod,
      'saleDate': saleDate.toIso8601String(),
      'status': status,
      'notes': notes,
    };
  }

  factory Sale.fromMap(Map<String, dynamic> map) {
    return Sale(
      id: map['id'],
      clientId: map['clientId'],
      total: map['total']?.toDouble() ?? 0.0,
      discount: map['discount']?.toDouble() ?? 0.0,
      finalAmount: map['finalAmount']?.toDouble() ?? 0.0,
      paymentMethod: map['paymentMethod'] ?? 'efectivo',
      saleDate: DateTime.parse(map['saleDate']),
      items: [],
      status: map['status'] ?? 'completada',
      notes: map['notes'],
    );
  }

  Sale copyWith({
    int? id,
    int? clientId,
    double? total,
    double? discount,
    double? finalAmount,
    String? paymentMethod,
    DateTime? saleDate,
    List<SaleItem>? items,
    String? status,
    String? notes,
  }) {
    return Sale(
      id: id ?? this.id,
      clientId: clientId ?? this.clientId,
      total: total ?? this.total,
      discount: discount ?? this.discount,
      finalAmount: finalAmount ?? this.finalAmount,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      saleDate: saleDate ?? this.saleDate,
      items: items ?? this.items,
      status: status ?? this.status,
      notes: notes ?? this.notes,
    );
  }
}

class SaleItem {
  final int? id;
  final int saleId;
  final int productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  SaleItem({
    this.id,
    required this.saleId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'saleId': saleId,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
    };
  }

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      id: map['id'],
      saleId: map['saleId'],
      productId: map['productId'],
      productName: map['productName'] ?? '',
      quantity: map['quantity'] ?? 0,
      unitPrice: map['unitPrice']?.toDouble() ?? 0.0,
      totalPrice: map['totalPrice']?.toDouble() ?? 0.0,
    );
  }
}
