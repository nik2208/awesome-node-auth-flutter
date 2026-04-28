/// Parses CSRF token cookies in priority order:
/// `__Host-csrf-token` > `__Secure-csrf-token` > `csrf-token`.
///
/// [cookieString] is the raw `document.cookie` string (or any semicolon-separated
/// cookie string). Returns `null` when no CSRF cookie is found.
String? parseCsrfFromCookies(String cookieString) {
  final cookies = <String, String>{};
  for (final part in cookieString.split(';')) {
    final idx = part.indexOf('=');
    if (idx == -1) continue;
    final name = part.substring(0, idx).trim();
    final value = part.substring(idx + 1).trim();
    cookies[name] = value;
  }
  return cookies['__Host-csrf-token'] ??
      cookies['__Secure-csrf-token'] ??
      cookies['csrf-token'];
}

/// Stub implementation for native platforms: always returns `null`
/// because CSRF tokens are managed via cookies on web only.
String? readCsrfToken() => null;

/// Always returns `false` on native because CSRF is a web-only concern.
bool isSameOrigin(String url, String apiPrefix) => false;
