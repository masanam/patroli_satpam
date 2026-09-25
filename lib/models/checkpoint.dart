class Checkpoint {
  final String id;
  final String name;
  final String siteId;
  final double latitude;
  final double longitude;
  final double radiusMeters;
  final int sequence;
  final bool isActive;

  const Checkpoint({
    required this.id,
    required this.name,
    required this.siteId,
    required this.latitude,
    required this.longitude,
    this.radiusMeters = 50,
    this.sequence = 0,
    this.isActive = true,
  });

  factory Checkpoint.fromJson(Map<String, dynamic> json, String id) {
    return Checkpoint(
      id: id,
      name: json['name'] as String? ?? id,
      siteId: json['siteId'] as String? ?? '',
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      radiusMeters: (json['radiusMeters'] as num?)?.toDouble() ?? 50,
      sequence: (json['sequence'] as num?)?.toInt() ?? 0,
      isActive: json['isActive'] as bool? ?? true,
    );
  }
}
