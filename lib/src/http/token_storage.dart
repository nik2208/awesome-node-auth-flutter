/// Interface for persisting Bearer access and refresh tokens on native platforms.
///
/// The default implementation ([InMemoryTokenStorage]) keeps tokens only in
/// memory. Provide a custom implementation (e.g. using `flutter_secure_storage`)
/// if you need persistence across app restarts.
abstract class TokenStorage {
  /// Reads the stored access token, or `null` if none is stored.
  Future<String?> readAccessToken();

  /// Persists the given access [token].
  Future<void> writeAccessToken(String token);

  /// Reads the stored refresh token, or `null` if none is stored.
  Future<String?> readRefreshToken();

  /// Persists the given refresh [token].
  Future<void> writeRefreshToken(String token);

  /// Clears all stored tokens.
  Future<void> clear();
}

/// A simple in-memory [TokenStorage] implementation.
///
/// Tokens are lost when the app process ends. Use a custom implementation
/// backed by secure storage if persistence between restarts is required.
class InMemoryTokenStorage implements TokenStorage {
  String? _accessToken;
  String? _refreshToken;

  @override
  Future<String?> readAccessToken() async => _accessToken;

  @override
  Future<void> writeAccessToken(String token) async {
    _accessToken = token;
  }

  @override
  Future<String?> readRefreshToken() async => _refreshToken;

  @override
  Future<void> writeRefreshToken(String token) async {
    _refreshToken = token;
  }

  @override
  Future<void> clear() async {
    _accessToken = null;
    _refreshToken = null;
  }
}
