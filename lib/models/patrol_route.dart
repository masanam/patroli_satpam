import 'package:police_patrol_app/models/incident.dart';

class PatrolRoute {
  final String id;
  final String officerId;
  final DateTime startTime; // When the route recording started
  final DateTime? endTime; // When the route recording ended
  final List<LocationPoint> locations; // List of recorded locations
  final List<Incident>? incidents; // List of incidents reported during the patrol
  final String? sessionType; // 'patrol' | 'checkpoint'

  PatrolRoute({
    required this.id,
    required this.officerId,
    required this.startTime,
    this.endTime,
    required this.locations,
    this.incidents,
    this.sessionType,
  });

  // Convert a PatrolRoute object into a JSON map
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'officerId': officerId,
      'startTime': startTime.millisecondsSinceEpoch,
      'endTime': endTime?.millisecondsSinceEpoch,
      'locations': locations.map((location) => location.toJson()).toList(),
      'incidents': incidents?.map((incident) => incident.toJson()).toList(),
      if (sessionType != null) 'sessionType': sessionType,
    };
  }

  // Convert a JSON map into a PatrolRoute object
  // Safe: handles null/missing 'locations' dari Firebase
  factory PatrolRoute.fromJson(Map<String, dynamic> json) {
    // Safely parse locations – field bisa null atau kosong di Firebase
    List<LocationPoint> parsedLocations = [];
    final rawLocations = json['locations'];
    if (rawLocations is List) {
      for (final loc in rawLocations) {
        if (loc is Map<String, dynamic>) {
          try {
            parsedLocations.add(LocationPoint.fromJson(loc));
          } catch (_) {
            // skip titik yang corrupt
          }
        }
      }
    }

    return PatrolRoute(
      id: json['id'] as String? ?? '',
      officerId: json['officerId'] as String? ?? '',
      startTime: json['startTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['startTime'] as int)
          : DateTime.now(),
      endTime: json['endTime'] != null
          ? DateTime.fromMillisecondsSinceEpoch(json['endTime'] as int)
          : null,
      locations: parsedLocations,
      incidents: (json['incidents'] as List?)
          ?.whereType<Map<String, dynamic>>()
          .map((incidentJson) => Incident.fromJson(incidentJson))
          .toList(),
      sessionType: json['sessionType'] as String?,
    );
  }
}

class LocationPoint {
  final double latitude;
  final double longitude;
  final DateTime timestamp;

  LocationPoint({
    required this.latitude,
    required this.longitude,
    required this.timestamp,
  });

  // Convert a LocationPoint object into a JSON map
  Map<String, dynamic> toJson() {
    return {
      'latitude': latitude,
      'longitude': longitude,
      'timestamp': timestamp.millisecondsSinceEpoch,
    };
  }

  // Convert a JSON map into a LocationPoint object
  // Safe: cast num → double karena Firestore bisa kirim int atau double
  factory LocationPoint.fromJson(Map<String, dynamic> json) {
    return LocationPoint(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      timestamp: DateTime.fromMillisecondsSinceEpoch(
          (json['timestamp'] as num).toInt()),
    );
  }
}
