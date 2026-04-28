# Changelog

All notable changes to this project will be documented in this file.

The format is based on [Keep a Changelog](https://keepachangelog.com/en/1.1.0/).

## 1.9.2

- Added example project with a simple Node.js backend and Flutter frontend demonstrating usage of the package.

## 1.9.1

- README updated to give comprehensive usage instructions.

## 1.9.0

- version bump to 1.9.0, aligned with awesome-node-auth backend v1.9.0

## 1.8.5

- Initial public release, aligned with awesome-node-auth backend v1.8.5.
- Web (WASM-compatible) cookie + CSRF authentication via HttpOnly cookies and `X-CSRF-Token` header, same-origin only.
- Native (iOS, Android, Desktop) Bearer token authentication with pluggable `TokenStorage`.
- Automatic token refresh with concurrent-request deduplication.
- Full API coverage: login, register, logout, 2FA (TOTP / SMS / magic-link), email verification and change, password reset and change, account linking, session management, account deletion.
- `AuthState.userStream` replays the current user to new subscribers immediately upon subscription.
- WASM-compatible: no `dart:html`, no `dart:io`, no native plugins.

## 0.1.0

- Initial release.
- Web (WASM-compatible) cookie + CSRF authentication.
- Native Bearer token authentication with pluggable `TokenStorage`.
- Full API coverage: login, register, 2FA (TOTP/SMS/magic-link), email
  verification, account linking, session management.
