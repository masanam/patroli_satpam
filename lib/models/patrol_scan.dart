import 'package:cloud_firestore/cloud_firestore.dart';

class PatrolScan {
  final String id;
  final String sessionId;
  final String checkpointId;
  final String officerId;
  final double latitude;
  final double longitude;
  final double? accuracy;
  final bool isWithinRadius;
  final DateTime scannedAt;

  const PatrolScan({
    required this.id,
    required this.sessionId,
    required this.checkpointId,
    required this.officerId,
    required this.latitude,
    required this.longitude,
    required this.accuracy,
    required this.isWithinRadius,
    required this.scannedAt,
  });

  Map<String, dynamic> toJson() {
    return {
      'sessionId': sessionId,
      'checkpointId': checkpointId,
      'officerId': officerId,
      'latitude': latitude,
      'longitude': longitude,
      'accuracy': accuracy,
      'isWithinRadius': isWithinRadius,
      'scannedAt': FieldValue.serverTimestamp(),
      'clientScannedAt': scannedAt.millisecondsSinceEpoch,
    };
  }

  factory PatrolScan.fromJson(Map<String, dynamic> json, String id) {
    return PatrolScan(
      id: id,
      sessionId: json['sessionId'] as String? ?? '',
      checkpointId: json['checkpointId'] as String? ?? '',
      officerId: json['officerId'] as String? ?? '',
      latitude: (json['latitude'] as num?)?.toDouble() ?? 0.0,
      longitude: (json['longitude'] as num?)?.toDouble() ?? 0.0,
      accuracy: (json['accuracy'] as num?)?.toDouble(),
      isWithinRadius: json['isWithinRadius'] as bool? ?? false,
      scannedAt: json['scannedAt'] != null
          ? (json['scannedAt'] as Timestamp).toDate()
          : (json['clientScannedAt'] != null
              ? DateTime.fromMillisecondsSinceEpoch(
                  json['clientScannedAt'] as int)
              : DateTime.now()),
    );
  }
}
