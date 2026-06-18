class UserModel {
  final String id;
  final String name;
  final String email;
  final String role;
  final String county;
  final bool isActive;
  final String? createdAt;

  const UserModel({
    required this.id,
    required this.name,
    required this.email,
    required this.role,
    required this.county,
    required this.isActive,
    this.createdAt,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id']?.toString() ?? '',
      name: json['name'] ?? '',
      email: json['email'] ?? '',
      role: json['role'] ?? 'citizen',
      county: json['county'] ?? '',
      isActive: json['is_active'] ?? true,
      createdAt: json['created_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'role': role,
      'county': county,
      'is_active': isActive,
      'created_at': createdAt,
    };
  }

  bool get isCitizen => role == 'citizen';
  bool get isCountyOfficer => role == 'county_officer';
  bool get isPoliceOfficer => role == 'police_officer';
  bool get isAdmin => role == 'admin';

  UserModel copyWith({
    String? id,
    String? name,
    String? email,
    String? role,
    String? county,
    bool? isActive,
    String? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      county: county ?? this.county,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}

class AuthTokens {
  final String access;
  final String refresh;

  const AuthTokens({required this.access, required this.refresh});

  factory AuthTokens.fromJson(Map<String, dynamic> json) {
    return AuthTokens(
      access: json['access'] ?? '',
      refresh: json['refresh'] ?? '',
    );
  }
}