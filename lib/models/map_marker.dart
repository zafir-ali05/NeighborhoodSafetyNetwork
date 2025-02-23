class MapMarker {
  final String id;
  final double latitude;
  final double longitude;
  final String name;
  final String dangerLevel;
  final String? description;
  final DateTime timestamp;

  MapMarker({
    required this.id,
    required this.latitude,
    required this.longitude,
    required this.name,
    required this.dangerLevel,
    this.description,
    DateTime? timestamp,
  }) : timestamp = timestamp ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'name': name,
      'dangerLevel': dangerLevel,
      'description': description,
      'timestamp': timestamp.toIso8601String(),
    };
  }

  factory MapMarker.fromMap(String id, Map<String, dynamic> map) {
    return MapMarker(
      id: id,
      latitude: map['latitude'] ?? 0.0,
      longitude: map['longitude'] ?? 0.0,
      name: map['name'] ?? '',
      dangerLevel: map['dangerLevel'] ?? '',
      description: map['description'],
      timestamp: DateTime.parse(map['timestamp']),
    );
  }
}
