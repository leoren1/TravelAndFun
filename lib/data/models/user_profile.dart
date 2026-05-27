// lib/data/models/user_profile.dart
// Plain Dart model — no code generation required.

class UserProfile {
  final String id;
  final String name;
  final String title;
  final String avatarPath;
  final int level;
  final String levelTitle;
  final int xp;
  final int xpForNextLevel;
  final List<String> badgeIds;

  const UserProfile({
    required this.id,
    required this.name,
    required this.title,
    required this.avatarPath,
    required this.level,
    required this.levelTitle,
    required this.xp,
    required this.xpForNextLevel,
    required this.badgeIds,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) => UserProfile(
        id: json['id'] as String,
        name: json['name'] as String,
        title: json['title'] as String,
        avatarPath: json['avatarPath'] as String,
        level: json['level'] as int,
        levelTitle: json['levelTitle'] as String,
        xp: json['xp'] as int,
        xpForNextLevel: json['xpForNextLevel'] as int,
        badgeIds: (json['badgeIds'] as List<dynamic>).cast<String>(),
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'title': title,
        'avatarPath': avatarPath,
        'level': level,
        'levelTitle': levelTitle,
        'xp': xp,
        'xpForNextLevel': xpForNextLevel,
        'badgeIds': badgeIds,
      };

  UserProfile copyWith({
    String? id,
    String? name,
    String? title,
    String? avatarPath,
    int? level,
    String? levelTitle,
    int? xp,
    int? xpForNextLevel,
    List<String>? badgeIds,
  }) {
    return UserProfile(
      id: id ?? this.id,
      name: name ?? this.name,
      title: title ?? this.title,
      avatarPath: avatarPath ?? this.avatarPath,
      level: level ?? this.level,
      levelTitle: levelTitle ?? this.levelTitle,
      xp: xp ?? this.xp,
      xpForNextLevel: xpForNextLevel ?? this.xpForNextLevel,
      badgeIds: badgeIds ?? this.badgeIds,
    );
  }

  /// Fractional XP progress toward the next level (0.0 – 1.0).
  double get xpProgress =>
      xpForNextLevel > 0 ? (xp / xpForNextLevel).clamp(0.0, 1.0) : 0.0;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is UserProfile &&
          runtimeType == other.runtimeType &&
          id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'UserProfile(id: $id, name: $name, level: $level, xp: $xp)';
}
