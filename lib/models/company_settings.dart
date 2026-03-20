class CompanySettings {
  final int? id;
  final String companyName;
  final String taxId;
  final String address;
  final String phone;
  final String email;
  final String currencySymbol;
  final String? logoPath;
  final String? businessRuc;

  CompanySettings({
    this.id,
    required this.companyName,
    this.taxId = '',
    this.address = '',
    this.phone = '',
    this.email = '',
    this.currencySymbol = '\$',
    this.logoPath,
    this.businessRuc,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'companyName': companyName,
      'taxId': taxId,
      'address': address,
      'phone': phone,
      'email': email,
      'currencySymbol': currencySymbol,
      'logoPath': logoPath,
      'businessRuc': businessRuc,
    };
  }

  factory CompanySettings.fromMap(Map<String, dynamic> map) {
    return CompanySettings(
      id: map['id'],
      companyName: map['companyName'] ?? 'TauroStock',
      taxId: map['taxId'] ?? '',
      address: map['address'] ?? '',
      phone: map['phone'] ?? '',
      email: map['email'] ?? '',
      currencySymbol: map['currencySymbol'] ?? '\$',
      logoPath: map['logoPath'],
      businessRuc: map['businessRuc'],
    );
  }

  CompanySettings copyWith({
    int? id,
    String? companyName,
    String? taxId,
    String? address,
    String? phone,
    String? email,
    String? currencySymbol,
    String? logoPath,
    String? businessRuc,
  }) {
    return CompanySettings(
      id: id ?? this.id,
      companyName: companyName ?? this.companyName,
      taxId: taxId ?? this.taxId,
      address: address ?? this.address,
      phone: phone ?? this.phone,
      email: email ?? this.email,
      currencySymbol: currencySymbol ?? this.currencySymbol,
      logoPath: logoPath ?? this.logoPath,
      businessRuc: businessRuc ?? this.businessRuc,
    );
  }
}
