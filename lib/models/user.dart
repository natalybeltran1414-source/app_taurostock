class User {
  final int? id;
  final String email;
  final String password;
  final String fullName;
  final String role; // 'admin' o 'operador'
  final DateTime createdAt;
  final bool isActive;
  final String? imagePath; // ← NUEVO: Ruta de la foto de perfil

  User({
    this.id,
    required this.email,
    required this.password,
    required this.fullName,
    required this.role,
    required this.createdAt,
    this.isActive = true,
    this.imagePath, // ← NUEVO
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'email': email,
      'password': password,
      'fullName': fullName,
      'role': role,
      'createdAt': createdAt.toIso8601String(),
      'isActive': isActive ? 1 : 0,
      'imagePath': imagePath, // ← NUEVO
    };
  }

  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      id: map['id'],
      email: map['email'],
      password: map['password'],
      fullName: map['fullName'],
      role: map['role'],
      createdAt: DateTime.parse(map['createdAt']),
      isActive: map['isActive'] == 1,
      imagePath: map['imagePath'], // ← NUEVO
    );
  }

  User copyWith({
    int? id,
    String? email,
    String? password,
    String? fullName,
    String? role,
    DateTime? createdAt,
    bool? isActive,
    String? imagePath, // ← NUEVO
  }) {
    return User(
      id: id ?? this.id,
      email: email ?? this.email,
      password: password ?? this.password,
      fullName: fullName ?? this.fullName,
      role: role ?? this.role,
      createdAt: createdAt ?? this.createdAt,
      isActive: isActive ?? this.isActive,
      imagePath: imagePath ?? this.imagePath, // ← NUEVO
    );
  }
}