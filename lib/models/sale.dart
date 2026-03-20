class Sale {
  final int? id;
  final int clientId;
  final double total;
  final double discount;
  final double finalAmount;
  final String? paymentMethod;
  final DateTime saleDate;
  final List<SaleItem> items;
  final List<SalePayment> payments;
  final String status;
  final String? notes;
  final String? businessRuc; // ← NUEVO: v12

  Sale({
    this.id,
    required this.clientId,
    required this.total,
    this.discount = 0,
    required this.finalAmount,
    required this.paymentMethod,
    required this.saleDate,
    required this.items,
    this.payments = const [],
    this.status = 'completada',
    this.notes,
    this.businessRuc,
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
      'businessRuc': businessRuc,
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
      payments: [],
      status: map['status'] ?? 'completada',
      notes: map['notes'],
      businessRuc: map['businessRuc'],
    );
  }

  Sale copyWith({
    int? id,
    int? clientId,
    double? total,
    double? discount,
    double? finalAmount,
    DateTime? saleDate,
    List<SaleItem>? items,
    List<SalePayment>? payments,
    String? status,
    String? notes,
    String? businessRuc,
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
      payments: payments ?? this.payments,
      status: status ?? this.status,
      notes: notes ?? this.notes,
      businessRuc: businessRuc ?? this.businessRuc,
    );
  }
}

class SalePayment {
  final int? id;
  final int saleId;
  final String method;
  final double amount;

  SalePayment({
    this.id,
    required this.saleId,
    required this.method,
    required this.amount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'saleId': saleId,
      'method': method,
      'amount': amount,
    };
  }

  factory SalePayment.fromMap(Map<String, dynamic> map) {
    return SalePayment(
      id: map['id'],
      saleId: map['saleId'],
      method: map['method'] ?? 'efectivo',
      amount: map['amount']?.toDouble() ?? 0.0,
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
