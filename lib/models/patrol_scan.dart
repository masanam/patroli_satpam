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
}
