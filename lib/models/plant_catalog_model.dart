/// Model representing a single plant identification record in the user's catalog.
class PlantCatalogModel {
  final int? id; // Auto-increment PK
  final String userId; // FK to Users table
  final String scientificName;
  final String commonName;
  final String? localName;
  final double confidenceScore;
  final String imagePath; // Local file path to the captured image
  final double? latitude;
  final double? longitude;
  final String xaiReasoning; // Explainable AI justification text
  final String? safetyWarnings;
  final String? preparationMethods;
  final String? family;
  final String? edibilityStatus;
  final String? habitat;
  final String? nutritionalHighlights;
  final DateTime timestamp;
  final int isSynced; // 0 = not synced to cloud, 1 = synced
  final String verificationStatus; // 'verified' or 'pending'

  PlantCatalogModel({
    this.id,
    required this.userId,
    required this.scientificName,
    required this.commonName,
    this.localName,
    required this.confidenceScore,
    required this.imagePath,
    this.latitude,
    this.longitude,
    required this.xaiReasoning,
    this.safetyWarnings,
    this.preparationMethods,
    this.family,
    this.edibilityStatus,
    this.habitat,
    this.nutritionalHighlights,
    required this.timestamp,
    this.isSynced = 0,
    this.verificationStatus = 'verified',
  });

  /// Convert to a Map for SQLite insertion.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'user_id': userId,
      'scientific_name': scientificName,
      'common_name': commonName,
      'local_name': localName,
      'confidence_score': confidenceScore,
      'image_path': imagePath,
      'latitude': latitude,
      'longitude': longitude,
      'xai_reasoning': xaiReasoning,
      'safety_warnings': safetyWarnings,
      'preparation_methods': preparationMethods,
      'family': family,
      'edibility_status': edibilityStatus,
      'habitat': habitat,
      'nutritional_highlights': nutritionalHighlights,
      'timestamp': timestamp.toIso8601String(),
      'is_synced': isSynced,
      'verification_status': verificationStatus,
    };
  }

  /// Construct from a SQLite row Map.
  factory PlantCatalogModel.fromMap(Map<String, dynamic> map) {
    return PlantCatalogModel(
      id: map['id'] as int?,
      userId: map['user_id'] as String,
      scientificName: map['scientific_name'] as String,
      commonName: map['common_name'] as String,
      localName: map['local_name'] as String?,
      confidenceScore: (map['confidence_score'] as num).toDouble(),
      imagePath: map['image_path'] as String,
      latitude: map['latitude'] != null ? (map['latitude'] as num).toDouble() : null,
      longitude: map['longitude'] != null ? (map['longitude'] as num).toDouble() : null,
      xaiReasoning: map['xai_reasoning'] as String,
      safetyWarnings: map['safety_warnings'] as String?,
      preparationMethods: map['preparation_methods'] as String?,
      family: map['family'] as String?,
      edibilityStatus: map['edibility_status'] as String?,
      habitat: map['habitat'] as String?,
      nutritionalHighlights: map['nutritional_highlights'] as String?,
      timestamp: DateTime.parse(map['timestamp'] as String),
      isSynced: map['is_synced'] as int? ?? 0,
      verificationStatus: map['verification_status'] as String? ?? 'verified',
    );
  }

  PlantCatalogModel copyWith({
    int? id,
    String? userId,
    String? scientificName,
    String? commonName,
    String? localName,
    double? confidenceScore,
    String? imagePath,
    double? latitude,
    double? longitude,
    String? xaiReasoning,
    String? safetyWarnings,
    String? preparationMethods,
    String? family,
    String? edibilityStatus,
    String? habitat,
    String? nutritionalHighlights,
    DateTime? timestamp,
    int? isSynced,
    String? verificationStatus,
  }) {
    return PlantCatalogModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      scientificName: scientificName ?? this.scientificName,
      commonName: commonName ?? this.commonName,
      localName: localName ?? this.localName,
      confidenceScore: confidenceScore ?? this.confidenceScore,
      imagePath: imagePath ?? this.imagePath,
      latitude: latitude ?? this.latitude,
      longitude: longitude ?? this.longitude,
      xaiReasoning: xaiReasoning ?? this.xaiReasoning,
      safetyWarnings: safetyWarnings ?? this.safetyWarnings,
      preparationMethods: preparationMethods ?? this.preparationMethods,
      family: family ?? this.family,
      edibilityStatus: edibilityStatus ?? this.edibilityStatus,
      habitat: habitat ?? this.habitat,
      nutritionalHighlights: nutritionalHighlights ?? this.nutritionalHighlights,
      timestamp: timestamp ?? this.timestamp,
      isSynced: isSynced ?? this.isSynced,
      verificationStatus: verificationStatus ?? this.verificationStatus,
    );
  }
}
