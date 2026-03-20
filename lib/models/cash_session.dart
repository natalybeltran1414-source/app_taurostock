class CashSession {
  final int? id;
  final double openingAmount;
  final double? closingAmount;
  final double? expectedAmount;
  final DateTime openingDate;
  final DateTime? closingDate;
  final String status; // 'open', 'closed'
  final int userId;
  final String? businessRuc; // ← NUEVO: v12
  final String? notes;

  CashSession({
    this.id,
    required this.openingAmount,
    this.closingAmount,
    this.expectedAmount,
    required this.openingDate,
    this.closingDate,
    required this.status,
    required this.userId,
    this.businessRuc,
    this.notes,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'openingAmount': openingAmount,
      'closingAmount': closingAmount,
      'expectedAmount': expectedAmount,
      'openingDate': openingDate.toIso8601String(),
      'closingDate': closingDate?.toIso8601String(),
      'status': status,
      'userId': userId,
      'businessRuc': businessRuc,
      'notes': notes,
    };
  }

  factory CashSession.fromMap(Map<String, dynamic> map) {
    return CashSession(
      id: map['id'],
      openingAmount: map['openingAmount'],
      closingAmount: map['closingAmount'],
      expectedAmount: map['expectedAmount'],
      openingDate: DateTime.parse(map['openingDate']),
      closingDate: map['closingDate'] != null ? DateTime.parse(map['closingDate']) : null,
      status: map['status'],
      userId: map['userId'],
      businessRuc: map['businessRuc'],
      notes: map['notes'],
    );
  }

  CashSession copyWith({
    int? id,
    double? openingAmount,
    double? closingAmount,
    double? expectedAmount,
    DateTime? openingDate,
    DateTime? closingDate,
    String? status,
    int? userId,
    String? businessRuc,
    String? notes,
  }) {
    return CashSession(
      id: id ?? this.id,
      openingAmount: openingAmount ?? this.openingAmount,
      closingAmount: closingAmount ?? this.closingAmount,
      expectedAmount: expectedAmount ?? this.expectedAmount,
      openingDate: openingDate ?? this.openingDate,
      closingDate: closingDate ?? this.closingDate,
      status: status ?? this.status,
      userId: userId ?? this.userId,
      businessRuc: businessRuc ?? this.businessRuc,
      notes: notes ?? this.notes,
    );
  }
}
