/// Model representing a registered user of the application.
class UserModel {
  final String id; // Will map to Firebase UID when cloud sync is enabled
  final String username;
  final String email;
  final String passwordHash;
  final String? profileImage;
  final DateTime createdAt;

  UserModel({
    required this.id,
    required this.username,
    required this.email,
    required this.passwordHash,
    this.profileImage,
    required this.createdAt,
  });

  /// Convert to a Map for SQLite insertion.
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'username': username,
      'email': email,
      'password_hash': passwordHash,
      'profile_image': profileImage,
      'created_at': createdAt.toIso8601String(),
    };
  }

  /// Construct from a SQLite row Map.
  factory UserModel.fromMap(Map<String, dynamic> map) {
    return UserModel(
      id: map['id'] as String,
      username: map['username'] as String,
      email: map['email'] as String,
      passwordHash: map['password_hash'] as String,
      profileImage: map['profile_image'] as String?,
      createdAt: DateTime.parse(map['created_at'] as String),
    );
  }

  UserModel copyWith({
    String? id,
    String? username,
    String? email,
    String? passwordHash,
    String? profileImage,
    DateTime? createdAt,
  }) {
    return UserModel(
      id: id ?? this.id,
      username: username ?? this.username,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      profileImage: profileImage ?? this.profileImage,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
