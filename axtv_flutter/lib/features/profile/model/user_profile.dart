class UserProfile {
  final String? firstName; // Nome
  final String? lastName; // Cognome
  final String? email; // Email
  final List<String> languages; // Lingue parlate (lista codici lingua: ['it', 'en', ecc.])
  final String? country; // Paese di origine (codice paese: 'it', 'fr', ecc.)

  const UserProfile({
    this.firstName,
    this.lastName,
    this.email,
    this.languages = const [],
    this.country,
  });

  factory UserProfile.fromJson(Map<String, dynamic> json) {
    // Supporta sia formato vecchio (singola lingua) che nuovo (lista lingue)
    final languagesJson = json['languages'];
    List<String> languages = [];
    if (languagesJson != null) {
      if (languagesJson is List) {
        languages = List<String>.from(languagesJson);
      }
    } else if (json['language'] != null) {
      // Migrazione da formato vecchio (singola lingua)
      languages = [json['language'] as String];
    }

    return UserProfile(
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      email: json['email'] as String?,
      languages: languages,
      country: json['country'] as String?,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'firstName': firstName,
      'lastName': lastName,
      'email': email,
      'languages': languages,
      'country': country,
    };
  }

  UserProfile copyWith({
    String? firstName,
    String? lastName,
    String? email,
    List<String>? languages,
    String? country,
  }) {
    return UserProfile(
      firstName: firstName ?? this.firstName,
      lastName: lastName ?? this.lastName,
      email: email ?? this.email,
      languages: languages ?? this.languages,
      country: country ?? this.country,
    );
  }
}
