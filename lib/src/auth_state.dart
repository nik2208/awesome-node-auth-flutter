import 'dart:async';

import 'auth_user.dart';

/// Reactive authentication state that notifies listeners of user changes.
class AuthState {
  final StreamController<AuthUser?> _controller =
      StreamController<AuthUser?>.broadcast();

  AuthUser? _currentUser;
  bool _isInitialized = false;

  /// Stream that emits the current user whenever authentication state changes.
  ///
  /// Emits `null` when the user is not authenticated.
  ///
  /// New subscribers always receive the current value immediately upon
  /// subscription, followed by future state changes.
  Stream<AuthUser?> get userStream async* {
    yield _currentUser;
    yield* _controller.stream;
  }

  /// The currently authenticated user, or `null` if not authenticated.
  AuthUser? get currentUser => _currentUser;

  /// Whether the user is currently authenticated.
  bool get isAuthenticated => _currentUser != null;

  /// Whether [AuthClient] has completed its initial session check.
  bool get isInitialized => _isInitialized;

  /// Updates the current user and notifies all listeners.
  void setUser(AuthUser? user) {
    _currentUser = user;
    if (!_controller.isClosed) {
      _controller.add(user);
    }
  }

  /// Marks the auth client as initialized (first session check complete).
  void setInitialized() {
    _isInitialized = true;
  }

  /// Releases resources held by this state object.
  void dispose() {
    _controller.close();
  }
}
