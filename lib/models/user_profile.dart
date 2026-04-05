class UserProfile {
  String? id;
  String Nom;
  String prenom;
  String location;
  double superficie;
  String type_culture;
  String exploitation;
  DateTime createdAt;
  DateTime updatedAt;

  UserProfile({
    this.id,
    required this.Nom,
    required this.prenom,
    required this.location,
    required this.superficie,
    required this.type_culture,
    required this.exploitation,
    required this.createdAt,
    required this.updatedAt,
  });

  // Convertir un objet Firebase en UserProfile
  factory UserProfile.fromMap(Map<String, dynamic> map, String id) {
    return UserProfile(
      id: id,
      Nom: map['Nom'] ?? '',
      prenom: map['prenom'] ?? '',
      location: map['location'] ?? '',
      superficie: (map['superficie'] ?? 0).toDouble(),
      type_culture: map['type_culture'] ?? '',
      exploitation: map['exploitation'] ?? '',
      createdAt: DateTime.parse(map['createdAt'] ?? DateTime.now().toIso8601String()),
      updatedAt: DateTime.parse(map['updatedAt'] ?? DateTime.now().toIso8601String()),
    );
  }

  // Convertir UserProfile en Map pour Firebase
  Map<String, dynamic> toMap() {
    return {
      'Nom': Nom,
      'prenom': prenom,
      'location': location,
      'superficie': superficie,
      'type_culture': type_culture,
      'exploitation': exploitation,
      'createdAt': createdAt.toIso8601String(),
      'updatedAt': updatedAt.toIso8601String(),
    };
  }

  // Copier avec modifications (utile pour les mises à jour)
  UserProfile copyWith({
    String? Nom,
    String? prenom,
    String? location,
    double? superficie,
    String? type_culture,
    String? exploitation,
    DateTime? updatedAt,
  }) {
    return UserProfile(
      id: this.id,
      Nom: Nom ?? this.Nom,
      prenom: prenom ?? this.prenom,
      location: location ?? this.location,
      superficie: superficie ?? this.superficie,
      type_culture: type_culture ?? this.type_culture,
      exploitation: exploitation ?? this.exploitation,
      createdAt: this.createdAt,
      updatedAt: updatedAt ?? DateTime.now(),
    );
  }
}