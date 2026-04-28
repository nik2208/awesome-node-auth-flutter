/// Represents an active user session.
class SessionInfo {
  /// Unique session handle used to identify and revoke this session.
  final String handle;

  /// User-agent string of the browser or client that created this session.
  final String? userAgent;

  /// IP address from which this session was created.
  final String? ipAddress;

  /// Timestamp when this session was created.
  final DateTime? createdAt;

  /// Timestamp of the last activity for this session.
  final DateTime? lastActiveAt;

  /// Whether this is the currently active session for the authenticated user.
  final bool isCurrent;

  const SessionInfo({
    required this.handle,
    this.userAgent,
    this.ipAddress,
    this.createdAt,
    this.lastActiveAt,
    this.isCurrent = false,
  });

  factory SessionInfo.fromJson(Map<String, dynamic> json) {
    return SessionInfo(
      handle: json['handle'] as String,
      userAgent: json['userAgent'] as String?,
      ipAddress: json['ipAddress'] as String?,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String)
          : null,
      lastActiveAt: json['lastActiveAt'] != null
          ? DateTime.tryParse(json['lastActiveAt'] as String)
          : null,
      isCurrent: json['isCurrent'] as bool? ?? false,
    );
  }

  Map<String, dynamic> toJson() => {
        'handle': handle,
        if (userAgent != null) 'userAgent': userAgent,
        if (ipAddress != null) 'ipAddress': ipAddress,
        if (createdAt != null) 'createdAt': createdAt!.toIso8601String(),
        if (lastActiveAt != null)
          'lastActiveAt': lastActiveAt!.toIso8601String(),
        'isCurrent': isCurrent,
      };
}
