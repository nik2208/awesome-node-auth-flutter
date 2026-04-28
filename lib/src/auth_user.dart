/// Represents the authenticated user returned by the backend.
class AuthUser {
  /// Subject identifier — the stable unique ID for the user.
  final String sub;

  /// The user's email address.
  final String email;

  /// Whether the user's email address has been verified.
  final bool isEmailVerified;

  /// Optional database ID (may differ from [sub] on some backends).
  final String? id;

  /// The user's first name.
  final String? firstName;

  /// The user's last name.
  final String? lastName;

  /// The user's display name.
  final String? name;

  /// The user's phone number.
  final String? phoneNumber;

  /// The user's primary role string.
  final String? role;

  /// The OAuth provider used for the most recent login (e.g. `'github'`).
  final String? loginProvider;

  /// Whether TOTP two-factor authentication is currently enabled.
  final bool? isTotpEnabled;

  /// Whether the user has a password set (may be `false` for OAuth-only users).
  final bool? hasPassword;

  /// Timestamp of the user's last successful login.
  final DateTime? lastLogin;

  /// Arbitrary key-value metadata attached to the user by the backend.
  final Map<String, dynamic>? metadata;

  /// List of roles assigned to the user.
  final List<String>? roles;

  /// List of permissions granted to the user.
  final List<String>? permissions;

  /// Whether the user has administrator privileges.
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
