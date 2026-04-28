// ignore: avoid_web_libraries_in_flutter
import 'package:web/web.dart' as web;

import 'csrf_cookie_parser.dart';
export 'csrf_cookie_parser.dart' show parseCsrfFromCookies;

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
    return isSameOriginPure(url, apiPrefix, web.window.location.origin);
  } catch (_) {
    return false;
  }
}
