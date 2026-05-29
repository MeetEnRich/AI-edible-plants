/// Model representing indigenous/cultural metadata for a known plant species.
/// This table acts as a local reference repository for localized botanical knowledge.
class IndigenousMetadataModel {
  final int? id;
  final String scientificName;
  final String family;
  final String? igboName;
  final String? hausaName;
  final String? yorubaName;
  final String description;
  final String preparationMethods;
  final String safetyWarnings;

  IndigenousMetadataModel({
    this.id,
    required this.scientificName,
    required this.family,
    this.igboName,
    this.hausaName,
    this.yorubaName,
    required this.description,
    required this.preparationMethods,
    required this.safetyWarnings,
  });

  /// Convert to a Map for SQLite insertion.
  Map<String, dynamic> toMap() {
    return {
      if (id != null) 'id': id,
      'scientific_name': scientificName,
      'family': family,
      'igbo_name': igboName,
      'hausa_name': hausaName,
      'yoruba_name': yorubaName,
      'description': description,
      'preparation_methods': preparationMethods,
      'safety_warnings': safetyWarnings,
    };
  }

  /// Construct from a SQLite row Map.
  factory IndigenousMetadataModel.fromMap(Map<String, dynamic> map) {
    return IndigenousMetadataModel(
      id: map['id'] as int?,
      scientificName: map['scientific_name'] as String,
      family: map['family'] as String,
      igboName: map['igbo_name'] as String?,
      hausaName: map['hausa_name'] as String?,
      yorubaName: map['yoruba_name'] as String?,
      description: map['description'] as String,
      preparationMethods: map['preparation_methods'] as String,
      safetyWarnings: map['safety_warnings'] as String,
    );
  }
}
