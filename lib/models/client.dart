class Client {
  final int? id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String? identification; 
  final double totalPurchases;
  final double accountBalance;
  final String? businessRuc; // ← NUEVO: v12
  final DateTime createdAt;
  final bool isActive;
  final int loyaltyPoints;

  Client({
    this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    this.identification,
    this.totalPurchases = 0,
    this.accountBalance = 0,
    this.businessRuc,
    required this.createdAt,
    this.isActive = true,
    this.loyaltyPoints = 0,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'identification': identification,
      'totalPurchases': totalPurchases,
      'accountBalance': accountBalance,
      'businessRuc': businessRuc,
      'loyaltyPoints': loyaltyPoints,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive ? 1 : 0,
    };
  }

  factory Client.fromMap(Map<String, dynamic> map) {
    return Client(
      id: map['id'],
      name: map['name'],
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      address: map['address'] ?? '',
      identification: map['identification'],
      totalPurchases: map['totalPurchases']?.toDouble() ?? 0.0,
      accountBalance: map['accountBalance']?.toDouble() ?? 0.0,
      businessRuc: map['businessRuc'],
      loyaltyPoints: map['loyaltyPoints'] ?? 0,
      createdAt: DateTime.parse(map['createdAt']),
      isActive: map['isActive'] == 1,
    );
  }

  Client copyWith({
    int? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? identification,
    double? totalPurchases,
    double? accountBalance,
    String? businessRuc,
    DateTime? createdAt,
    bool? isActive,
    int? loyaltyPoints,
  }) {
    return Client(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      identification: identification ?? this.identification, 
      totalPurchases: totalPurchases ?? this.totalPurchases,
      accountBalance: accountBalance ?? this.accountBalance,
      businessRuc: businessRuc ?? this.businessRuc,
      loyaltyPoints: loyaltyPoints ?? this.loyaltyPoints,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  bool get hasDebt => accountBalance < 0;
  double get debt => accountBalance < 0 ? -accountBalance : 0;
}
