/// UI configuration returned by the backend's `/ui/config` endpoint.
class UiConfig {
  /// Whether new user registration is enabled.
  final bool registrationEnabled;

  /// Whether magic-link (passwordless email) login is enabled.
  final bool magicLinkEnabled;

  /// Whether SMS one-time-password login is enabled.
  final bool smsEnabled;

  /// Whether TOTP two-factor authentication is enabled.
  final bool totpEnabled;

  /// Whether GitHub OAuth login is enabled.
  final bool githubEnabled;

  /// Whether Google OAuth login is enabled.
  final bool googleEnabled;

  /// List of OAuth provider names available for login.
  final List<String> availableProviders;

  /// Additional backend-specific configuration fields.
  final Map<String, dynamic>? extra;

  const UiConfig({
    this.registrationEnabled = true,
    this.magicLinkEnabled = false,
    this.smsEnabled = false,
    this.totpEnabled = false,
    this.githubEnabled = false,
    this.googleEnabled = false,
    this.availableProviders = const [],
    this.extra,
  });

  factory UiConfig.fromJson(Map<String, dynamic> json) {
    return UiConfig(
      registrationEnabled: json['registrationEnabled'] as bool? ?? true,
      magicLinkEnabled: json['magicLinkEnabled'] as bool? ?? false,
      smsEnabled: json['smsEnabled'] as bool? ?? false,
      totpEnabled: json['totpEnabled'] as bool? ?? false,
      githubEnabled: json['githubEnabled'] as bool? ?? false,
      googleEnabled: json['googleEnabled'] as bool? ?? false,
      availableProviders:
          (json['availableProviders'] as List<dynamic>?)?.cast<String>() ??
              const [],
      extra: json['extra'] as Map<String, dynamic>?,
    );
  }

  Map<String, dynamic> toJson() => {
        'registrationEnabled': registrationEnabled,
        'magicLinkEnabled': magicLinkEnabled,
        'smsEnabled': smsEnabled,
        'totpEnabled': totpEnabled,
        'githubEnabled': githubEnabled,
        'googleEnabled': googleEnabled,
        'availableProviders': availableProviders,
        if (extra != null) 'extra': extra,
      };
}
