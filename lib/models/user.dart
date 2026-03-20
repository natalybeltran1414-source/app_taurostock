class User {
  final int? id;
  final String email;
  final String password;
  final String fullName;
  final String role; // 'admin' o 'empleado'
  final String businessRuc; // ← NUEVO: Identificador único de empresa
  final String businessName; // ← NUEVO: Nombre del negocio
  final DateTime createdAt;
  final bool isActive;
  final String? imagePath;

  User({
    this.id,
    required this.email,
    required this.password,
    required this.fullName,
    required this.role,
    required this.businessRuc,
    required this.businessName,
    required this.createdAt,
    this.isActive = true,
    this.imagePath,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'password': password,
      'fullName': fullName,
      'role': role,
      'businessRuc': businessRuc,
      'businessName': businessName,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive ? 1 : 0,
      'imagePath': imagePath,
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      email: map['email'],
      password: map['password'],
      fullName: map['fullName'],
      role: map['role'],
      businessRuc: map['businessRuc'] ?? '',
      businessName: map['businessName'] ?? '',
      createdAt: DateTime.parse(map['createdAt']),
      isActive: map['isActive'] == 1,
      imagePath: map['imagePath'],
    );
  }

  User copyWith({
    int? id,
    String? email,
    String? password,
    String? fullName,
    String? role,
    String? businessRuc,
    String? businessName,
    DateTime? createdAt,
    bool? isActive,
    String? imagePath,
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      password: password ?? this.password,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      businessRuc: businessRuc ?? this.businessRuc,
      businessName: businessName ?? this.businessName,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      imagePath: imagePath ?? this.imagePath,
    );
  }
}
