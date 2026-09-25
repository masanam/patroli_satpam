import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:police_patrol_app/models/patrol_scan.dart';
import 'package:police_patrol_app/services/auth_service.dart';
import 'package:police_patrol_app/services/firebase_service.dart';
import 'package:uuid/uuid.dart';

class CheckpointScannerPage extends StatefulWidget {
  final String sessionId;

  const CheckpointScannerPage({super.key, required this.sessionId});

  @override
  State<CheckpointScannerPage> createState() => _CheckpointScannerPageState();
}

class _CheckpointScannerPageState extends State<CheckpointScannerPage> {
  final FirebaseService _firebaseService = FirebaseService();
  final MobileScannerController _scannerController = MobileScannerController();
  bool _processing = false;
  String? _message;
  bool _success = false;

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_processing) return;
    final value = capture.barcodes.firstOrNull?.rawValue?.trim();
    if (value == null || value.isEmpty) return;

    setState(() {
      _processing = true;
      _message = 'Memvalidasi checkpoint...';
      _success = false;
    });
    await _scannerController.stop();

    try {
      final checkpoint = await _firebaseService.getCheckpoint(value);
      if (checkpoint == null || !checkpoint.isActive) {
        throw StateError('Checkpoint tidak terdaftar atau tidak aktif.');
      }

      final user = AuthService().currentUser;
      if (user == null) throw StateError('Sesi login sudah berakhir.');

      final location = Location();
      final serviceEnabled = await location.serviceEnabled();
      if (!serviceEnabled) throw StateError('Aktifkan layanan lokasi.');
      final permission = await location.hasPermission();
      if (permission != PermissionStatus.granted) {
        throw StateError('Izin lokasi diperlukan untuk scan checkpoint.');
      }
      final locationData = await location.getLocation();
      final latitude = locationData.latitude;
      final longitude = locationData.longitude;
      if (latitude == null || longitude == null) {
        throw StateError('Lokasi saat ini tidak tersedia.');
      }

      final distance = _distanceInMeters(
        latitude,
        longitude,
        checkpoint.latitude,
        checkpoint.longitude,
      );
      if (distance > checkpoint.radiusMeters) {
        throw StateError(
          'Anda berada ${distance.round()} m dari checkpoint. '
          'Maksimal ${checkpoint.radiusMeters.round()} m.',
        );
      }

      if (await _firebaseService.hasCheckpointBeenScanned(
          widget.sessionId, checkpoint.id)) {
        throw StateError('Checkpoint ini sudah discan pada patroli ini.');
      }

      final scan = PatrolScan(
        id: const Uuid().v4(),
        sessionId: widget.sessionId,
        checkpointId: checkpoint.id,
        officerId: user.uid,
        latitude: latitude,
        longitude: longitude,
        accuracy: locationData.accuracy,
        isWithinRadius: true,
        scannedAt: DateTime.now(),
      );
      await _firebaseService.addPatrolScan(scan);

      if (!mounted) return;
      setState(() {
        _success = true;
        _message = 'Checkpoint ${checkpoint.name} berhasil dicatat.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(
          () => _message = error.toString().replaceFirst('Bad state: ', ''));
    } finally {
      if (mounted) setState(() => _processing = false);
    }
  }

  double _distanceInMeters(double latitude1, double longitude1,
      double latitude2, double longitude2) {
    const earthRadius = 6371000.0;
    final lat1 = latitude1 * math.pi / 180;
    final lat2 = latitude2 * math.pi / 180;
    final deltaLat = (latitude2 - latitude1) * math.pi / 180;
    final deltaLon = (longitude2 - longitude1) * math.pi / 180;
    final a = math.pow(math.sin(deltaLat / 2), 2) +
        math.cos(lat1) * math.cos(lat2) * math.pow(math.sin(deltaLon / 2), 2);
    return earthRadius * 2 * math.atan2(math.sqrt(a), math.sqrt(1 - a));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Scan Checkpoint'),
        actions: [
          IconButton(
            icon: const Icon(Icons.flash_on),
            onPressed: () => _scannerController.toggleTorch(),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: MobileScanner(
              controller: _scannerController,
              onDetect: _handleBarcode,
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              children: [
                Text(
                  _message ?? 'Arahkan kamera ke barcode checkpoint.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _success ? Colors.green : Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 12),
                if (_processing) const LinearProgressIndicator(),
                if (_success)
                  TextButton.icon(
                    onPressed: () {
                      setState(() {
                        _success = false;
                        _message = null;
                      });
                      _scannerController.start();
                    },
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('Scan checkpoint berikutnya'),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _scannerController.dispose();
    super.dispose();
  }
}
