import '../auth_user.dart';

/// Generic result type for auth operations.
///
/// [T] is the type of the success data payload.
class AuthResult<T> {
  /// Whether the operation succeeded.
  final bool success;

  /// The data payload on success, or `null` on failure.
  final T? data;

  /// A human-readable error message on failure, or `null` on success.
  final String? error;

  /// An optional machine-readable error code (e.g. `"SESSION_REVOKED"`).
  final String? errorCode;

  const AuthResult._({
    required this.success,
    this.data,
    this.error,
    this.errorCode,
  });

  /// Creates a successful result with optional [data].
  factory AuthResult.success([T? data]) =>
      AuthResult._(success: true, data: data);

  /// Creates a failed result with the given [error] message and optional [errorCode].
  factory AuthResult.failure(String error, {String? errorCode}) =>
      AuthResult._(success: false, error: error, errorCode: errorCode);

  @override
  String toString() =>
      'AuthResult(success: $success, data: $data, error: $error)';
}

/// Result returned by [AuthClient.login].
class LoginResult extends AuthResult<AuthUser> {
  /// Whether the login requires a two-factor authentication step.
  final bool requires2fa;

  /// Whether the user needs to set up 2FA before proceeding.
  final bool requires2FASetup;

  /// Temporary token used to complete the 2FA flow.
  final String? tempToken;

  /// The 2FA methods available to the user (e.g. `['totp', 'sms', 'magic-link']`).
  final List<String> availableMethods;

  const LoginResult._({
    required super.success,
    super.data,
    super.error,
    super.errorCode,
    this.requires2fa = false,
    this.requires2FASetup = false,
    this.tempToken,
    this.availableMethods = const [],
  }) : super._();

  factory LoginResult.authenticated(AuthUser user) => LoginResult._(
        success: true,
        data: user,
      );

  factory LoginResult.requires2FA({
    required String tempToken,
    required List<String> availableMethods,
    bool requires2FASetup = false,
  }) =>
      LoginResult._(
        success: true,
        requires2fa: true,
        requires2FASetup: requires2FASetup,
        tempToken: tempToken,
        availableMethods: availableMethods,
      );

  factory LoginResult.failure(String error, {String? errorCode}) =>
      LoginResult._(success: false, error: error, errorCode: errorCode);
}

/// Data returned when setting up TOTP two-factor authentication.
class TotpSetupData {
  /// The TOTP secret key.
  final String secret;

  /// A data URL for the QR code image.
  final String qrCode;

  const TotpSetupData({required this.secret, required this.qrCode});

  factory TotpSetupData.fromJson(Map<String, dynamic> json) => TotpSetupData(
        secret: json['secret'] as String,
        qrCode: json['qrCode'] as String,
      );
}
