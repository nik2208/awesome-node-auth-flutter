// ignore: avoid_web_libraries_in_flutter
import 'package:web/web.dart' as web;

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

/// Reads the CSRF token from `document.cookie` on web platforms.
///
/// Returns `null` if no CSRF cookie is present.
String? readCsrfToken() {
  try {
    return parseCsrfFromCookies(web.document.cookie);
  } catch (_) {
    return null;
  }
}

/// Returns `true` when [url] is same-origin with the backend determined by
/// [apiPrefix].
///
/// - If [apiPrefix] is absolute (starts with `http`): compare the origins of
///   [url] and [apiPrefix].
/// - If [apiPrefix] is relative: the backend is always same-origin, so any
///   [url] without an explicit scheme is considered same-origin.
bool isSameOrigin(String url, String apiPrefix) {
  try {
    final parsedUrl = Uri.tryParse(url);
    if (parsedUrl == null) return false;

    // Relative URL — same origin by definition.
    if (!parsedUrl.hasScheme) return true;

    if (apiPrefix.startsWith('http://') || apiPrefix.startsWith('https://')) {
      final parsedPrefix = Uri.tryParse(apiPrefix);
      if (parsedPrefix == null) return false;
      return parsedUrl.scheme == parsedPrefix.scheme &&
          parsedUrl.host == parsedPrefix.host &&
          parsedUrl.port == parsedPrefix.port;
    }

    // Relative apiPrefix — compare against window.location.origin.
    final windowOrigin = web.window.location.origin;
    final windowUri = Uri.tryParse(windowOrigin);
    if (windowUri == null) return false;
    return parsedUrl.scheme == windowUri.scheme &&
        parsedUrl.host == windowUri.host &&
        parsedUrl.port == windowUri.port;
  } catch (_) {
    return false;
  }
}
