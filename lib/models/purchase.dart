class Purchase {
  final int? id;
  final int providerId;
  final double total;
  final double discount;
  final double finalAmount;
  final String paymentStatus; // 'pagado', 'pendiente'
  final DateTime purchaseDate;
  final List<PurchaseItem> items;
  final String? businessRuc; // ← NUEVO: v12
  final String? notes;

  Purchase({
    this.id,
    required this.providerId,
    required this.total,
    this.discount = 0,
    required this.finalAmount,
    this.paymentStatus = 'pendiente',
    required this.purchaseDate,
    required this.items,
    this.businessRuc,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'providerId': providerId,
      'total': total,
      'discount': discount,
      'finalAmount': finalAmount,
      'paymentStatus': paymentStatus,
      'purchaseDate': purchaseDate.toIso8601String(),
      'businessRuc': businessRuc,
      'notes': notes,
    };
  }

  factory Purchase.fromMap(Map<String, dynamic> map) {
    return Purchase(
      id: map['id'],
      providerId: map['providerId'],
      total: map['total']?.toDouble() ?? 0.0,
      discount: map['discount']?.toDouble() ?? 0.0,
      finalAmount: map['finalAmount']?.toDouble() ?? 0.0,
      paymentStatus: map['paymentStatus'] ?? 'pendiente',
      purchaseDate: DateTime.parse(map['purchaseDate']),
      items: [],
      businessRuc: map['businessRuc'],
      notes: map['notes'],
    );
  }

  Purchase copyWith({
    int? id,
    int? providerId,
    double? total,
    double? discount,
    double? finalAmount,
    String? paymentStatus,
    DateTime? purchaseDate,
    List<PurchaseItem>? items,
    String? businessRuc,
    String? notes,
  }) {
    return Purchase(
      id: id ?? this.id,
      providerId: providerId ?? this.providerId,
      total: total ?? this.total,
      discount: discount ?? this.discount,
      finalAmount: finalAmount ?? this.finalAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      items: items ?? this.items,
      businessRuc: businessRuc ?? this.businessRuc,
      notes: notes ?? this.notes,
    );
  }
}

class PurchaseItem {
  final int? id;
  final int purchaseId;
  final int productId;
  final String productName;
  final int quantity;
  final double unitPrice;
  final double totalPrice;

  PurchaseItem({
    this.id,
    required this.purchaseId,
    required this.productId,
    required this.productName,
    required this.quantity,
    required this.unitPrice,
    required this.totalPrice,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'purchaseId': purchaseId,
      'productId': productId,
      'productName': productName,
      'quantity': quantity,
      'unitPrice': unitPrice,
      'totalPrice': totalPrice,
    };
  }

  factory PurchaseItem.fromMap(Map<String, dynamic> map) {
    return PurchaseItem(
      id: map['id'],
      purchaseId: map['purchaseId'],
      productId: map['productId'],
      productName: map['productName'] ?? '',
      quantity: map['quantity'] ?? 0,
      unitPrice: map['unitPrice']?.toDouble() ?? 0.0,
      totalPrice: map['totalPrice']?.toDouble() ?? 0.0,
    );
  }
}
