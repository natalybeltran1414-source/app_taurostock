class Product {
  final int? id;
  final String name;
  final String description;
  final double costPrice;
  final double salePrice;
  final int quantity;
  final int minStock;
  final String barcode;
  final String category;
  final String? imagePath; // ruta de la foto opcional
  final DateTime createdAt;
  final bool isActive;

  Product({
    this.id,
    required this.name,
    required this.description,
    required this.costPrice,
    required this.salePrice,
    required this.quantity,
    required this.minStock,
    required this.barcode,
    required this.category,
    this.imagePath,
    required this.createdAt,
    this.isActive = true,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'costPrice': costPrice,
      'salePrice': salePrice,
      'quantity': quantity,
      'minStock': minStock,
      'barcode': barcode,
      'category': category,
      'imagePath': imagePath,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive ? 1 : 0,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      id: map['id'],
      name: map['name'],
      description: map['description'] ?? '',
      costPrice: map['costPrice']?.toDouble() ?? 0.0,
      salePrice: map['salePrice']?.toDouble() ?? 0.0,
      quantity: map['quantity'] ?? 0,
      minStock: map['minStock'] ?? 0,
      barcode: map['barcode'] ?? '',
      category: map['category'] ?? '',
      imagePath: map['imagePath'],
      createdAt: DateTime.parse(map['createdAt']),
      isActive: map['isActive'] == 1,
    );
  }

  Product copyWith({
    int? id,
    String? name,
    String? description,
    double? costPrice,
    double? salePrice,
    int? quantity,
    int? minStock,
    String? barcode,
    String? category,
    String? imagePath,
    DateTime? createdAt,
    bool? isActive,
  }) {
    return Product(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      costPrice: costPrice ?? this.costPrice,
      salePrice: salePrice ?? this.salePrice,
      quantity: quantity ?? this.quantity,
      minStock: minStock ?? this.minStock,
      barcode: barcode ?? this.barcode,
      category: category ?? this.category,
      imagePath: imagePath ?? this.imagePath,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
    );
  }

  double get profit => (salePrice - costPrice) * quantity;
  bool get isLowStock => quantity <= minStock;
}
