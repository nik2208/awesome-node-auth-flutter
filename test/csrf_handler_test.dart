import 'package:flutter_test/flutter_test.dart';

import 'package:awesome_node_auth_flutter/src/http/csrf_handler_stub.dart';

void main() {
  group('parseCsrfFromCookies', () {
    test('returns null for empty cookie string', () {
      expect(parseCsrfFromCookies(''), isNull);
    });

    test('parses plain csrf-token cookie', () {
      expect(
        parseCsrfFromCookies('csrf-token=abc123'),
        equals('abc123'),
      );
    });

    test('parses __Secure-csrf-token cookie', () {
      expect(
        parseCsrfFromCookies('__Secure-csrf-token=secureToken; other=value'),
        equals('secureToken'),
      );
    });

    test('parses __Host-csrf-token cookie', () {
      expect(
        parseCsrfFromCookies('__Host-csrf-token=hostToken'),
        equals('hostToken'),
      );
    });

    test('__Host-csrf-token has highest priority over __Secure-csrf-token', () {
      expect(
        parseCsrfFromCookies(
          '__Host-csrf-token=host; __Secure-csrf-token=secure; csrf-token=plain',
        ),
        equals('host'),
      );
    });

    test('__Secure-csrf-token has higher priority than plain csrf-token', () {
      expect(
        parseCsrfFromCookies('__Secure-csrf-token=secure; csrf-token=plain'),
        equals('secure'),
      );
    });

    test('handles whitespace around cookie pairs', () {
      expect(
        parseCsrfFromCookies('  csrf-token = myToken ; session=abc'),
        equals('myToken'),
      );
    });

    test('returns null when no csrf cookie present', () {
      expect(
        parseCsrfFromCookies('session=abc; user=xyz'),
        isNull,
      );
    });

    test('handles cookie string with only separators', () {
      expect(parseCsrfFromCookies(';;;'), isNull);
    });

    test('handles cookie value with equals sign', () {
      // Cookie value may contain '=' (e.g. base64-encoded values).
      final result =
          parseCsrfFromCookies('csrf-token=base64==; session=abc');
      expect(result, isNotNull);
    });
  });

  group('stub readCsrfToken', () {
    test('always returns null on native', () {
      expect(readCsrfToken(), isNull);
    });
  });

  group('stub isSameOrigin', () {
    test('always returns false on native', () {
      expect(isSameOrigin('https://example.com/api', '/auth'), isFalse);
      expect(isSameOrigin('/auth/me', '/auth'), isFalse);
    });
  });
}
