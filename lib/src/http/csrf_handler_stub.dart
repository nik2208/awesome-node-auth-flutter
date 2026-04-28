export 'csrf_cookie_parser.dart' show parseCsrfFromCookies;

/// Stub implementation for native platforms: always returns `null`
/// because CSRF tokens are managed via cookies on web only.
String? readCsrfToken() => null;

/// Always returns `false` on native because CSRF is a web-only concern.
bool isSameOrigin(String url, String apiPrefix) => false;
