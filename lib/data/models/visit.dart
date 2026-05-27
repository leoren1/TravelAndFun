// lib/data/models/visit.dart
// Plain Dart model — no code generation required.

class Visit {
  final String id;
  final String placeId;
  final String userId;
  final DateTime visitedAt;
  final String photoPath;
  final double photoLatitude;
  final double photoLongitude;
  final DateTime photoTakenAt;
  final int rating;
  final String? note;
  final bool verified;

  const Visit({
    required this.id,
    required this.placeId,
    required this.userId,
    required this.visitedAt,
    required this.photoPath,
    required this.photoLatitude,
    required this.photoLongitude,
    required this.photoTakenAt,
    required this.rating,
    this.note,
    required this.verified,
  });

  factory Visit.fromJson(Map<String, dynamic> json) => Visit(
        id: json['id'] as String,
        placeId: json['placeId'] as String,
        userId: json['userId'] as String,
        visitedAt: DateTime.parse(json['visitedAt'] as String),
        photoPath: json['photoPath'] as String,
        photoLatitude: (json['photoLatitude'] as num).toDouble(),
        photoLongitude: (json['photoLongitude'] as num).toDouble(),
        photoTakenAt: DateTime.parse(json['photoTakenAt'] as String),
        rating: json['rating'] as int,
        note: json['note'] as String?,
        verified: json['verified'] as bool,
      );

  Map<String, dynamic> toJson() => {
        'id': id,
        'placeId': placeId,
        'userId': userId,
        'visitedAt': visitedAt.toIso8601String(),
        'photoPath': photoPath,
        'photoLatitude': photoLatitude,
        'photoLongitude': photoLongitude,
        'photoTakenAt': photoTakenAt.toIso8601String(),
        'rating': rating,
        'note': note,
        'verified': verified,
      };

  Visit copyWith({
    String? id,
    String? placeId,
    String? userId,
    DateTime? visitedAt,
    String? photoPath,
    double? photoLatitude,
    double? photoLongitude,
    DateTime? photoTakenAt,
    int? rating,
    String? note,
    bool? verified,
  }) {
    return Visit(
      id: id ?? this.id,
      placeId: placeId ?? this.placeId,
      userId: userId ?? this.userId,
      visitedAt: visitedAt ?? this.visitedAt,
      photoPath: photoPath ?? this.photoPath,
      photoLatitude: photoLatitude ?? this.photoLatitude,
      photoLongitude: photoLongitude ?? this.photoLongitude,
      photoTakenAt: photoTakenAt ?? this.photoTakenAt,
      rating: rating ?? this.rating,
      note: note ?? this.note,
      verified: verified ?? this.verified,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is Visit && runtimeType == other.runtimeType && id == other.id;

  @override
  int get hashCode => id.hashCode;

  @override
  String toString() =>
      'Visit(id: $id, placeId: $placeId, userId: $userId, verified: $verified)';
}
