// CSRF handler with platform-conditional exports.
//
// On web/WASM (when dart.library.js_interop is available) the web
// implementation backed by package:web is used. On native platforms the
// stub (no-op) implementation is used instead.
export 'csrf_handler_stub.dart'
    if (dart.library.js_interop) 'csrf_handler_web.dart';
