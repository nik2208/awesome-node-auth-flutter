import 'auth_user.dart';

/// Types of authentication lifecycle events.
enum AuthEventType {
  /// The session has expired (refresh failed).
  sessionExpired,

  /// The session was explicitly revoked on the server.
  sessionRevoked,

  /// The user logged out (either manually or due to an expired/revoked session).
  loggedOut,

  /// The user successfully logged in.
  loggedIn,

  /// The auth client has completed its initial session check.
  initialized,

  /// The user successfully confirmed an email change.
  emailChanged,
}

/// An event emitted by [AuthClient.events] to describe authentication lifecycle changes.
class AuthEvent {
  final AuthEventType type;
  final AuthUser? user;

  const AuthEvent({required this.type, this.user});

  @override
  String toString() => 'AuthEvent(type: $type, user: ${user?.email})';
}
