/// Configurazione di un repository per canali live
class RepositoryConfig {
  final String id;
  final String name;
  final String? description;
  final String baseUrl;
  final String? jsonPath;
  final String? m3uPath;
  final bool enabled;
  
  const RepositoryConfig({
    required this.id,
    required this.name,
    this.description,
    required this.baseUrl,
    this.jsonPath,
    this.m3uPath,
    this.enabled = true,
  });
  
  /// URL completo per caricare i canali
  String get fullUrl {
    final path = m3uPath ?? jsonPath ?? '';
    if (path.isEmpty) return baseUrl;
    if (path.startsWith('http')) return path;
    return '$baseUrl$path';
  }
  
  /// Crea una copia con valori aggiornati
  RepositoryConfig copyWith({
    String? id,
    String? name,
    String? description,
    String? baseUrl,
    String? jsonPath,
    String? m3uPath,
    bool? enabled,
  }) {
    return RepositoryConfig(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      baseUrl: baseUrl ?? this.baseUrl,
      jsonPath: jsonPath ?? this.jsonPath,
      m3uPath: m3uPath ?? this.m3uPath,
      enabled: enabled ?? this.enabled,
    );
  }
  
  /// Converte in Map per storage
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'baseUrl': baseUrl,
      'jsonPath': jsonPath,
      'm3uPath': m3uPath,
      'enabled': enabled,
    };
  }
  
  /// Crea da Map (da storage)
  factory RepositoryConfig.fromMap(Map<String, dynamic> map) {
    return RepositoryConfig(
      id: map['id'] as String,
      name: map['name'] as String,
      description: map['description'] as String?,
      baseUrl: map['baseUrl'] as String,
      jsonPath: map['jsonPath'] as String?,
      m3uPath: map['m3uPath'] as String?,
      enabled: map['enabled'] as bool? ?? true,
    );
  }
}
