/// Represents the authenticated user returned by the backend.
class AuthUser {
  final String sub;
  final String email;
  final bool isEmailVerified;
  final String? id;
  final String? firstName;
  final String? lastName;
  final String? name;
  final String? phoneNumber;
  final String? role;
  final String? loginProvider;
  final bool? isTotpEnabled;
  final bool? hasPassword;
  final DateTime? lastLogin;
  final Map<String, dynamic>? metadata;
  final List<String>? roles;
  final List<String>? permissions;
  final bool? isAdmin;

  const AuthUser({
    required this.sub,
    required this.email,
    required this.isEmailVerified,
    this.id,
    this.firstName,
    this.lastName,
    this.name,
    this.phoneNumber,
    this.role,
    this.loginProvider,
    this.isTotpEnabled,
    this.hasPassword,
    this.lastLogin,
    this.metadata,
    this.roles,
    this.permissions,
    this.isAdmin,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      sub: json['sub'] as String,
      email: json['email'] as String,
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      id: json['id'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      name: json['name'] as String?,
      phoneNumber: json['phoneNumber'] as String?,
      role: json['role'] as String?,
      loginProvider: json['loginProvider'] as String?,
      isTotpEnabled: json['isTotpEnabled'] as bool?,
      hasPassword: json['hasPassword'] as bool?,
      lastLogin: json['lastLogin'] != null
          ? DateTime.tryParse(json['lastLogin'] as String)
          : null,
      metadata: json['metadata'] as Map<String, dynamic>?,
      roles: (json['roles'] as List<dynamic>?)?.cast<String>(),
      permissions: (json['permissions'] as List<dynamic>?)?.cast<String>(),
      isAdmin: json['isAdmin'] as bool?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'sub': sub,
      'email': email,
      'isEmailVerified': isEmailVerified,
      if (id != null) 'id': id,
      if (firstName != null) 'firstName': firstName,
      if (lastName != null) 'lastName': lastName,
      if (name != null) 'name': name,
      if (phoneNumber != null) 'phoneNumber': phoneNumber,
      if (role != null) 'role': role,
      if (loginProvider != null) 'loginProvider': loginProvider,
      if (isTotpEnabled != null) 'isTotpEnabled': isTotpEnabled,
      if (hasPassword != null) 'hasPassword': hasPassword,
      if (lastLogin != null) 'lastLogin': lastLogin!.toIso8601String(),
      if (metadata != null) 'metadata': metadata,
      if (roles != null) 'roles': roles,
      if (permissions != null) 'permissions': permissions,
      if (isAdmin != null) 'isAdmin': isAdmin,
    };
  }
}
