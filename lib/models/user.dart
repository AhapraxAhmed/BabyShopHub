class UserProfile {
  final String uid;
  final String email;
  final String displayName;
  final int avatarIndex;
  final bool isMfaEnabled;
  final bool isTotpEnabled; // Support for Authenticator app 2FA
  final String? totpSecret;  // Google Authenticator secret key
  final String? mfaPhoneNumber;
  final List<String> wishlistedProductIds;
  final String role; // 'user' or 'admin'

  UserProfile({
    required this.uid,
    required this.email,
    required this.displayName,
    this.avatarIndex = 0,
    this.isMfaEnabled = false,
    this.isTotpEnabled = false,
    this.totpSecret,
    this.mfaPhoneNumber,
    this.wishlistedProductIds = const [],
    this.role = 'user',
  });

  UserProfile copyWith({
    String? uid,
    String? email,
    String? displayName,
    int? avatarIndex,
    bool? isMfaEnabled,
    bool? isTotpEnabled,
    String? totpSecret,
    String? mfaPhoneNumber,
    List<String>? wishlistedProductIds,
    String? role,
  }) {
    return UserProfile(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      displayName: displayName ?? this.displayName,
      avatarIndex: avatarIndex ?? this.avatarIndex,
      isMfaEnabled: isMfaEnabled ?? this.isMfaEnabled,
      isTotpEnabled: isTotpEnabled ?? this.isTotpEnabled,
      totpSecret: totpSecret ?? this.totpSecret,
      mfaPhoneNumber: mfaPhoneNumber ?? this.mfaPhoneNumber,
      wishlistedProductIds: wishlistedProductIds ?? this.wishlistedProductIds,
      role: role ?? this.role,
    );
  }

  // Predefined avatar selections with premium asset keys/indexes (emojis replaced by labels)
  static const List<String> avatars = [
    'Newborn',
    'Baby Panda',
    'Teddy Bear',
    'Baby Unicorn',
    'Tiger Cub',
    'Baby Owl',
  ];
}
