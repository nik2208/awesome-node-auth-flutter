import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:mocktail/mocktail.dart';

import 'package:awesome_node_auth_flutter/src/http/auth_http_client.dart';

class MockHttpClient extends Mock implements http.Client {}

/// Helper that builds an [http.Response] with a JSON body.
http.Response jsonResponse(
  int statusCode, [
  Map<String, dynamic>? body,
]) {
  return http.Response(
    body != null ? jsonEncode(body) : '',
    statusCode,
    headers: {'content-type': 'application/json'},
  );
}

void main() {
  late MockHttpClient mockClient;
  late AuthHttpClient authHttp;
  int refreshCallCount = 0;
  int logoutCallCount = 0;

  setUp(() {
    registerFallbackValue(Uri());
    mockClient = MockHttpClient();
    refreshCallCount = 0;
    logoutCallCount = 0;

    authHttp = AuthHttpClient(
      inner: mockClient,
      apiPrefix: 'https://api.example.com/auth',
    );

    authHttp.setRefreshHandler(() async {
      refreshCallCount++;
      // Simulate a successful refresh.
      return true;
    });

    authHttp.setLogoutHandler(({bool revoked = false}) async {
      logoutCallCount++;
    });
  });

  group('refresh deduplication', () {
    test('concurrent 401 responses produce exactly one refresh call', () async {
      // All three endpoints return 401 on the first call.
      // After refresh they return 200.
      var meCallCount = 0;

      when(() => mockClient.get(
            Uri.parse('https://api.example.com/auth/me'),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async {
        meCallCount++;
        if (meCallCount <= 3) return jsonResponse(401);
        return jsonResponse(
            200, {'sub': 'user1', 'email': 'a@b.com', 'isEmailVerified': true});
      });

      when(() => mockClient.get(
                Uri.parse('https://api.example.com/auth/profile'),
                headers: any(named: 'headers'),
              ))
          .thenAnswer((_) async => meCallCount > 3
              ? jsonResponse(200,
                  {'sub': 'user1', 'email': 'a@b.com', 'isEmailVerified': true})
              : jsonResponse(401));

      when(() => mockClient.get(
                Uri.parse('https://api.example.com/auth/sessions'),
                headers: any(named: 'headers'),
              ))
          .thenAnswer((_) async => meCallCount > 3
              ? jsonResponse(200, <String, dynamic>{})
              : jsonResponse(401));

      when(() => mockClient.post(
            Uri.parse('https://api.example.com/auth/refresh'),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => jsonResponse(200));

      // Fire three concurrent requests — all will 401 simultaneously.
      await Future.wait([
        authHttp.get('/me'),
        authHttp.get('/profile'),
        authHttp.get('/sessions'),
      ]);

      // Despite three concurrent 401s, refresh must have been called only once.
      expect(refreshCallCount, equals(1),
          reason: 'Only one refresh call expected even with concurrent 401s');
    });

    test('refresh failure triggers logout', () async {
      // Endpoint always returns 401.
      when(() => mockClient.get(
            Uri.parse('https://api.example.com/auth/me'),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => jsonResponse(401));

      // Refresh fails.
      authHttp.setRefreshHandler(() async => false);

      await authHttp.get('/me');

      expect(logoutCallCount, equals(1));
    });

    test('SESSION_REVOKED triggers logout without refresh', () async {
      when(() => mockClient.get(
            Uri.parse('https://api.example.com/auth/me'),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => jsonResponse(401, {
            'code': 'SESSION_REVOKED',
            'message': 'Session has been revoked',
          }));

      await authHttp.get('/me');

      expect(refreshCallCount, equals(0),
          reason: 'No refresh should be attempted for SESSION_REVOKED');
      expect(logoutCallCount, equals(1));
    });
  });

  group('auth endpoint exclusion', () {
    void mockEndpoint(String path, int status) {
      when(() => mockClient.post(
            Uri.parse('https://api.example.com/auth$path'),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => jsonResponse(status));
    }

    test('401 on /login does NOT trigger refresh', () async {
      mockEndpoint('/login', 401);
      await authHttp
          .post('/login', body: {'email': 'x@y.com', 'password': 'p'});
      expect(refreshCallCount, equals(0));
    });

    test('401 on /logout does NOT trigger refresh', () async {
      mockEndpoint('/logout', 401);
      await authHttp.post('/logout');
      expect(refreshCallCount, equals(0));
    });

    test('401 on /refresh does NOT trigger refresh', () async {
      mockEndpoint('/refresh', 401);
      await authHttp.post('/refresh');
      expect(refreshCallCount, equals(0));
    });

    test('401 on /register does NOT trigger refresh', () async {
      mockEndpoint('/register', 401);
      await authHttp.post('/register', body: {});
      expect(refreshCallCount, equals(0));
    });

    test('401 on /forgot-password does NOT trigger refresh', () async {
      mockEndpoint('/forgot-password', 401);
      await authHttp.post('/forgot-password', body: {'email': 'a@b.com'});
      expect(refreshCallCount, equals(0));
    });

    test('401 on /reset-password does NOT trigger refresh', () async {
      mockEndpoint('/reset-password', 401);
      await authHttp
          .post('/reset-password', body: {'password': 'p', 'token': 't'});
      expect(refreshCallCount, equals(0));
    });

    test('401 on /verify-email does NOT trigger refresh', () async {
      when(() => mockClient.get(
            any(),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async => jsonResponse(401));
      await authHttp.get('/verify-email', queryParameters: {'token': 'tok'});
      expect(refreshCallCount, equals(0));
    });

    test('401 on /2fa/verify does NOT trigger refresh', () async {
      mockEndpoint('/2fa/verify', 401);
      await authHttp
          .post('/2fa/verify', body: {'tempToken': 't', 'totpCode': '123456'});
      expect(refreshCallCount, equals(0));
    });
  });

  group('/me endpoint retry', () {
    test('401 on /me DOES trigger refresh', () async {
      var meCallCount = 0;
      when(() => mockClient.get(
            Uri.parse('https://api.example.com/auth/me'),
            headers: any(named: 'headers'),
          )).thenAnswer((_) async {
        meCallCount++;
        if (meCallCount == 1) return jsonResponse(401);
        return jsonResponse(
            200, {'sub': 'u', 'email': 'a@b.com', 'isEmailVerified': true});
      });

      when(() => mockClient.post(
            Uri.parse('https://api.example.com/auth/refresh'),
            headers: any(named: 'headers'),
            body: any(named: 'body'),
          )).thenAnswer((_) async => jsonResponse(200));

      await authHttp.get('/me');

      expect(refreshCallCount, equals(1),
          reason: '401 on /me should trigger one refresh');
    });
  });
}
