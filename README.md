# awesome_node_auth_flutter

Flutter/Dart authentication client for [awesome-node-auth](https://github.com/nik2208/awesome-node-auth) backends.

Supports **web** (including WASM) via HttpOnly cookies + CSRF, and **native** (iOS, Android, Desktop) via Bearer token.

## Installation

```yaml
dependencies:
  awesome_node_auth_flutter: ^1.8.5
```

## Quick start

```dart
final auth = AuthClient(AuthOptions(apiPrefix: '/api/auth'));
await auth.checkSession();

// Listen to state
auth.state.userStream.listen((user) {
  if (user != null) print('Logged in: ${user.email}');
});

// Login
final result = await auth.login('user@example.com', 'password');
if (result.requires2fa) {
  // handle 2FA with result.tempToken
}
```

## Platform behaviour

| Platform | Auth mode | Token management |
|---|---|---|
| Web / WASM | Cookie (HttpOnly) + CSRF | Browser |
| iOS / Android / Desktop | Bearer token | In-memory (override with custom `TokenStorage`) |

## Configuration

```dart
AuthOptions(
  apiPrefix: '/api/auth',     // Backend prefix (relative or absolute)
  loginUrl: '/login',         // Redirect URL shown on session expiry
  headless: false,            // Set true to disable auto-redirect on logout
  initializeOnStartup: true,  // Call checkSession() automatically
)
```

## Custom token storage

```dart
class SecureTokenStorage implements TokenStorage {
  @override
  Future<String?> readAccessToken() async { /* ... */ }
  @override
  Future<void> writeAccessToken(String? token) async { /* ... */ }
  @override
  Future<void> clear() async { /* ... */ }
}

final auth = AuthClient(
  AuthOptions(
    apiPrefix: '/api/auth',
    tokenStorage: SecureTokenStorage(),
  ),
);
```

## Supported features

- Login / register / logout
- Magic-link authentication
- SMS one-time-password login
- TOTP two-factor authentication
- SMS two-factor authentication
- Magic-link two-factor authentication
- Email verification and change
- Password reset and change
- Account linking and conflict resolution
- Session management (list active sessions, revoke session)
- Account deletion
- Server-sent events (`getToolsStream`) — web only

## License

MIT
