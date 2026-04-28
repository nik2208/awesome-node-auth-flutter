import 'dart:async';
import 'dart:js_interop';

// ignore: avoid_web_libraries_in_flutter
import 'package:web/web.dart' as web;
import 'package:http/http.dart' as http;

import '../auth_client.dart';
import '../auth_options.dart';
import '../http/auth_http_client.dart';
import '../http/csrf_handler.dart' as csrf;
import 'base_auth_client.dart';

/// Factory function called by the conditional import in [AuthClient].
///
/// On web/WASM platforms (`dart.library.js_interop` available) this function
/// is used.
AuthClient createAuthClient(AuthOptions options, {http.Client? httpClient}) {
  final inner = httpClient ?? http.Client();

  final authHttp = AuthHttpClient(
    inner: inner,
    apiPrefix: options.apiPrefix,
    // Always call readCsrfToken — it returns null when no cookie is present,
    // which causes the header to be omitted. For cross-origin APIs, CORS will
    // block the request regardless of this header.
    csrfProvider: csrf.readCsrfToken,
  );

  return WebAuthClient(options, authHttp);
}

/// Web-platform implementation of [AuthClient].
///
/// Uses cookie-based authentication with CSRF protection:
/// - Reads the CSRF token from `document.cookie` via `package:web`.
/// - Attaches `X-CSRF-Token` on requests (when the cookie is present).
/// - Does **not** manage Bearer tokens — the browser handles HttpOnly cookies.
class WebAuthClient extends BaseAuthClient {
  WebAuthClient(super.options, super.httpClient);

  @override
  void redirectToLogin() {
    try {
      web.window.location.href = options.effectiveLoginUrl;
    } catch (_) {}
  }

  /// Returns a server-sent events stream from `$apiPrefix/tools/stream`.
  @override
  Stream<String> getToolsStream() {
    try {
      final prefix = options.apiPrefix;
      final url = prefix.startsWith('http')
          ? '$prefix/tools/stream'
          : '$prefix/tools/stream';

      final controller = StreamController<String>.broadcast();
      final es = web.EventSource(url);

      es.onmessage = (web.MessageEvent event) {
        if (!controller.isClosed) {
          controller.add(event.data.dartify()?.toString() ?? '');
        }
      }.toJS;

      es.onerror = (web.Event _) {
        if (!controller.isClosed) {
          es.close();
          controller.close();
        }
      }.toJS;

      controller.onCancel = es.close;

      return controller.stream;
    } catch (_) {
      return const Stream.empty();
    }
  }
}
