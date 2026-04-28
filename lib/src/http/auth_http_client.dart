import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;

/// Identifier used to signal that the session was revoked on the server.
const _kSessionRevoked = 'SESSION_REVOKED';

/// Auth endpoints that should NOT trigger a refresh + retry on 401/403.
const _kNoRetryEndpoints = {
  'login',
  'logout',
  'refresh',
  'register',
  'forgot-password',
  'reset-password',
  'verify-email',
};

/// Two-segment endpoint that must be excluded separately.
const _kNoRetryTwoSegment = '2fa/verify';

/// Provides CSRF token for web given the full request URL.
///
/// The [url] parameter allows the provider to perform a same-origin check
/// and return `null` for cross-origin requests so the header is omitted.
typedef CsrfTokenProvider = String? Function(String url);

/// Provides the current Bearer access token (native only).
typedef BearerTokenProvider = Future<String?> Function();

/// Persists a new Bearer access token received after a refresh (native only).
typedef BearerTokenSetter = Future<void> Function(String token);

/// Called when the session ends (expired, revoked, or user logout).
typedef LogoutCallback = Future<void> Function({bool revoked});

/// Core HTTP client that wraps [http.Client] and adds:
///
/// - CSRF header injection (web, same-origin)
/// - Bearer token injection (native)
/// - Automatic refresh + retry on 401/403 with deduplication
/// - Session-revoked detection
class AuthHttpClient {
  final http.Client _inner;
  final String _apiPrefix;

  final CsrfTokenProvider? _csrfProvider;
  final BearerTokenProvider? _bearerProvider;
  final BearerTokenSetter? _bearerSetter;

  LogoutCallback? _onLogout;
  Future<bool> Function()? _refreshHandler;

  /// In-flight refresh deduplicator.
  Completer<bool>? _refreshCompleter;

  AuthHttpClient({
    required http.Client inner,
    required String apiPrefix,
    CsrfTokenProvider? csrfProvider,
    BearerTokenProvider? bearerProvider,
    BearerTokenSetter? bearerSetter,
  })  : _inner = inner,
        _apiPrefix = apiPrefix,
        _csrfProvider = csrfProvider,
        _bearerProvider = bearerProvider,
        _bearerSetter = bearerSetter;

  /// Registers the callback invoked when the session ends.
  void setLogoutHandler(LogoutCallback handler) => _onLogout = handler;

  /// Registers the function that performs the token refresh.
  void setRefreshHandler(Future<bool> Function() handler) =>
      _refreshHandler = handler;

  // -------------------------------------------------------------------------
  // URL helpers
  // -------------------------------------------------------------------------

  Uri _buildUri(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return Uri.parse(path);
    }
    if (_apiPrefix.startsWith('http://') || _apiPrefix.startsWith('https://')) {
      return Uri.parse('$_apiPrefix$path');
    }
    return Uri(path: '$_apiPrefix$path');
  }

  // -------------------------------------------------------------------------
  // Endpoint exclusion
  // -------------------------------------------------------------------------

  bool _isExcludedEndpoint(String path) {
    final segments = path.split('/').where((s) => s.isNotEmpty).toList();
    if (segments.isEmpty) return false;

    final last = segments.last;
    if (_kNoRetryEndpoints.contains(last)) return true;

    if (segments.length >= 2) {
      final twoSeg = '${segments[segments.length - 2]}/$last';
      if (twoSeg == _kNoRetryTwoSegment) return true;
    }

    return false;
  }

  // -------------------------------------------------------------------------
  // Header helpers
  // -------------------------------------------------------------------------

  Future<Map<String, String>> _buildHeaders(
    Map<String, String>? extra,
    String path, {
    bool includeAuthHeaders = true,
  }) async {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
      ...?extra,
    };

    if (includeAuthHeaders) {
      final url = _buildUri(path).toString();
      final csrf = _csrfProvider?.call(url);
      if (csrf != null) headers['X-CSRF-Token'] = csrf;

      if (_bearerProvider != null) {
        final bearer = await _bearerProvider();
        if (bearer != null) headers['Authorization'] = 'Bearer $bearer';
      }
    }

    return headers;
  }

  // -------------------------------------------------------------------------
  // Public HTTP verbs
  // -------------------------------------------------------------------------

  Future<http.Response> get(
    String path, {
    Map<String, String>? headers,
    Map<String, String>? queryParameters,
  }) =>
      _send('GET', path, headers: headers, queryParameters: queryParameters);

  Future<http.Response> post(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) =>
      _send('POST', path, headers: headers, body: body);

  Future<http.Response> patch(
    String path, {
    Map<String, String>? headers,
    Object? body,
  }) =>
      _send('PATCH', path, headers: headers, body: body);

  Future<http.Response> delete(
    String path, {
    Map<String, String>? headers,
  }) =>
      _send('DELETE', path, headers: headers);

  // -------------------------------------------------------------------------
  // Core send logic
  // -------------------------------------------------------------------------

  Future<http.Response> _send(
    String method,
    String path, {
    Map<String, String>? headers,
    Object? body,
    Map<String, String>? queryParameters,
  }) async {
    final allHeaders = await _buildHeaders(headers, path);
    final response =
        await _rawSend(method, path, allHeaders, body, queryParameters);

    if ((response.statusCode == 401 || response.statusCode == 403) &&
        !_isExcludedEndpoint(path)) {
      return _handleUnauthorized(method, path, response,
          headers: headers, body: body, queryParameters: queryParameters);
    }

    return response;
  }

  Future<http.Response> _rawSend(
    String method,
    String path,
    Map<String, String> headers,
    Object? body,
    Map<String, String>? queryParameters,
  ) async {
    var uri = _buildUri(path);
    if (queryParameters != null && queryParameters.isNotEmpty) {
      uri = uri.replace(queryParameters: {
        ...uri.queryParameters,
        ...queryParameters,
      });
    }

    switch (method) {
      case 'GET':
        return _inner.get(uri, headers: headers);
      case 'DELETE':
        return _inner.delete(uri, headers: headers);
      case 'POST':
        final encoded =
            body is String ? body : (body != null ? jsonEncode(body) : null);
        return _inner.post(uri, headers: headers, body: encoded);
      case 'PATCH':
        final encoded =
            body is String ? body : (body != null ? jsonEncode(body) : null);
        return _inner.patch(uri, headers: headers, body: encoded);
      default:
        throw ArgumentError('Unsupported HTTP method: $method');
    }
  }

  // -------------------------------------------------------------------------
  // 401 / 403 interception
  // -------------------------------------------------------------------------

  /// Returns `true` when the response body contains a JSON object with
  /// `"code": "SESSION_REVOKED"`, matching the backend contract.
  bool _isSessionRevoked(http.Response response) {
    try {
      final decoded = jsonDecode(response.body);
      if (decoded is Map<String, dynamic>) {
        return decoded['code'] == _kSessionRevoked;
      }
    } catch (_) {}
    return false;
  }

  Future<http.Response> _handleUnauthorized(
    String method,
    String path,
    http.Response response, {
    Map<String, String>? headers,
    Object? body,
    Map<String, String>? queryParameters,
  }) async {
    if (_isSessionRevoked(response)) {
      await _onLogout?.call(revoked: true);
      return response;
    }

    final refreshed = await _doRefresh();
    if (refreshed) {
      final retryHeaders = await _buildHeaders(headers, path);
      return _rawSend(method, path, retryHeaders, body, queryParameters);
    } else {
      await _onLogout?.call(revoked: false);
      return response;
    }
  }

  // -------------------------------------------------------------------------
  // Refresh with deduplication
  // -------------------------------------------------------------------------

  Future<bool> _doRefresh() async {
    if (_refreshCompleter != null) {
      return _refreshCompleter!.future;
    }

    _refreshCompleter = Completer<bool>();
    try {
      final success = await (_refreshHandler?.call() ?? Future.value(false));
      _refreshCompleter!.complete(success);
      return success;
    } catch (_) {
      _refreshCompleter!.complete(false);
      return false;
    } finally {
      _refreshCompleter = null;
    }
  }

  // -------------------------------------------------------------------------
  // Internal refresh endpoint call
  // -------------------------------------------------------------------------

  /// Calls `POST $apiPrefix/refresh` directly, bypassing retry logic.
  Future<bool> callRefreshEndpoint() async {
    try {
      final headers = await _buildHeaders(null, '/refresh');
      final response = await _rawSend('POST', '/refresh', headers, null, null);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        if (_bearerSetter != null) {
          try {
            final decoded = jsonDecode(response.body);
            if (decoded is Map<String, dynamic>) {
              final newToken = decoded['accessToken'] as String?;
              if (newToken != null) await _bearerSetter(newToken);
            }
          } catch (_) {}
        }
        return true;
      }
      return false;
    } catch (_) {
      return false;
    }
  }

  void close() => _inner.close();
}
