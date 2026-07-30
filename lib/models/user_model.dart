class UserModel {
  final int id;
  final String name;
  final String? username;
  final String? email;
  final String? avatarUrl;
  final List<String> roles;
  final List<String> permissions;
  final String? desaName;
  final String? kecamatanName;
  final String? desaCode;
  final String? token;
  final String? tokenType;

  UserModel({
    required this.id,
    required this.name,
    this.username,
    this.email,
    this.avatarUrl,
    this.roles = const [],
    this.permissions = const [],
    this.desaName,
    this.kecamatanName,
    this.desaCode,
    this.token,
    this.tokenType,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    return UserModel(
      id: json['id'] ?? 0,
      name: json['name'] ?? '',
      username: json['username'],
      email: json['email'],
      avatarUrl: json['avatar_url'],
      roles: json['roles'] != null ? List<String>.from(json['roles']) : [],
      permissions:
          json['permissions'] != null ? List<String>.from(json['permissions']) : [],
      desaName: json['desa_name'],
      kecamatanName: json['kecamatan_name'],
      desaCode: json['desa_code'],
      token: json['token'],
      tokenType: json['token_type'],
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'username': username,
        'email': email,
        'avatar_url': avatarUrl,
        'roles': roles,
        'permissions': permissions,
        'desa_name': desaName,
        'kecamatan_name': kecamatanName,
        'desa_code': desaCode,
        'token': token,
        'token_type': tokenType,
      };

  String get roleLabel => roles.isNotEmpty ? roles.first.toUpperCase() : 'USER';

  bool get isOperator => roles.any((r) => r.toLowerCase() == 'operator');

  bool get isKader => roles.any((r) => r.toLowerCase() == 'kader');
}
