class ProviderModel {
  final int? id;
  final String name;
  final String phone;
  final String email;
  final String address;
  final String city;
  final String taxId;
  final double totalPurchases;
  final double accountBalance;
  final String? businessRuc; // ← NUEVO: v12
  final DateTime createdAt;
  final bool isActive;

  ProviderModel({
    this.id,
    required this.name,
    required this.phone,
    required this.email,
    required this.address,
    required this.city,
    this.taxId = '',
    this.totalPurchases = 0,
    this.accountBalance = 0,
    this.businessRuc,
    required this.createdAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'phone': phone,
      'email': email,
      'address': address,
      'city': city,
      'taxId': taxId,
      'totalPurchases': totalPurchases,
      'accountBalance': accountBalance,
      'businessRuc': businessRuc,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive ? 1 : 0,
    };
  }

  factory ProviderModel.fromMap(Map<String, dynamic> map) {
    return ProviderModel(
      id: map['id'],
      name: map['name'],
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      address: map['address'] ?? '',
      city: map['city'] ?? '',
      taxId: map['taxId'] ?? '',
      totalPurchases: map['totalPurchases']?.toDouble() ?? 0.0,
      accountBalance: map['accountBalance']?.toDouble() ?? 0.0,
      businessRuc: map['businessRuc'],
      createdAt: DateTime.parse(map['createdAt']),
      isActive: map['isActive'] == 1,
    );
  }

  ProviderModel copyWith({
    int? id,
    String? name,
    String? phone,
    String? email,
    String? address,
    String? city,
    String? taxId,
    double? totalPurchases,
    double? accountBalance,
    String? businessRuc,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return ProviderModel(
      id: id ?? this.id,
      name: name ?? this.name,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      address: address ?? this.address,
      city: city ?? this.city,
      taxId: taxId ?? this.taxId,
      totalPurchases: totalPurchases ?? this.totalPurchases,
      accountBalance: accountBalance ?? this.accountBalance,
      businessRuc: businessRuc ?? this.businessRuc,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  bool get hasDebt => accountBalance > 0;
}
