import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:location/location.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:police_patrol_app/models/patrol_route.dart';
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
  String? _checkpointName;
  String? _checkpointId;
  DateTime? _scannedAt;
  double? _distanceMeters;
  double? _locationAccuracy;

  Future<void> _handleBarcode(BarcodeCapture capture) async {
    if (_processing) return;
    final value = capture.barcodes.firstOrNull?.rawValue?.trim();
    if (value == null || value.isEmpty) return;
    debugPrint('Checkpoint QR payload code units: ${value.codeUnits}');

    setState(() {
      _processing = true;
      _message = 'Memvalidasi checkpoint...';
      _success = false;
      _checkpointName = null;
      _checkpointId = null;
      _scannedAt = null;
      _distanceMeters = null;
      _locationAccuracy = null;
    });
    await _scannerController.stop();

    var stage = 'membaca checkpoint';
    try {
      // Validasi format barcode: hanya proses jika nilai sesuai format checkpoint
      final isValidFormat = RegExp(r'^CP-[A-Z0-9]+-[A-Z0-9]+$').hasMatch(value);
      if (!isValidFormat) {
        throw StateError(
          'QR tidak valid: "$value".\n'
          'Pastikan Anda menscan QR checkpoint yang terdaftar (contoh: CP-GATE-001).',
        );
      }

      final checkpoint = await _firebaseService.getCheckpoint(value);
      if (checkpoint == null || !checkpoint.isActive) {
        throw StateError('Checkpoint tidak terdaftar atau tidak aktif.');
      }

      stage = 'memvalidasi sesi login';
      final user = AuthService().currentUser;
      if (user == null) throw StateError('Sesi login sudah berakhir.');

      stage = 'memeriksa izin lokasi';
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

      stage = 'memeriksa scan duplikat';
      if (await _firebaseService.hasCheckpointBeenScanned(
          widget.sessionId, checkpoint.id)) {
        throw StateError('Checkpoint ini sudah discan pada patroli ini.');
      }

      final scannedAt = DateTime.now();
      final scan = PatrolScan(
        id: const Uuid().v4(),
        sessionId: widget.sessionId,
        checkpointId: checkpoint.id,
        officerId: user.uid,
        latitude: latitude,
        longitude: longitude,
        accuracy: locationData.accuracy,
        isWithinRadius: true,
        scannedAt: scannedAt,
      );
      stage = 'menyimpan hasil scan';
      await _firebaseService.addPatrolScan(scan);

      // Append koordinat GPS ke locations array route utama
      // agar Detail Route dapat menampilkan Jarak, Rata-rata & Titik GPS
      await _firebaseService.appendLocationToRoute(
        widget.sessionId,
        LocationPoint(
          latitude: latitude,
          longitude: longitude,
          timestamp: scannedAt,
        ),
      );


      if (!mounted) return;
      setState(() {
        _success = true;
        _message = 'Checkpoint ${checkpoint.name} berhasil dicatat.';
        _checkpointName = checkpoint.name;
        _checkpointId = checkpoint.id;
        _scannedAt = scannedAt;
        _distanceMeters = distance;
        _locationAccuracy = locationData.accuracy;
      });
    } catch (error) {
      if (!mounted) return;
      final errorMessage = error.toString().replaceFirst('Bad state: ', '');
      setState(() => _message = 'Gagal saat $stage: $errorMessage');
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

  String _formatScannedAt(BuildContext context) {
    final scannedAt = _scannedAt;
    if (scannedAt == null) return '';
    final localTime = scannedAt.toLocal();
    final date = MaterialLocalizations.of(context).formatMediumDate(localTime);
    final time = TimeOfDay.fromDateTime(localTime).format(context);
    return '$date, $time';
  }

  void _startNextScan() {
    setState(() {
      _message = null;
      _success = false;
      _checkpointName = null;
      _checkpointId = null;
      _scannedAt = null;
      _distanceMeters = null;
      _locationAccuracy = null;
    });
    _scannerController.start();
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
      body: Stack(
        children: [
          Positioned.fill(
            child: MobileScanner(
              controller: _scannerController,
              onDetect: _handleBarcode,
            ),
          ),
          Positioned(
            top: 12,
            left: 12,
            right: 12,
            child: SafeArea(
              bottom: false,
              child: Card(
                color: Colors.black87,
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Icon(
                            _success
                                ? Icons.check_circle
                                : _processing
                                    ? Icons.hourglass_top
                                    : _message == null
                                        ? Icons.qr_code_scanner
                                        : Icons.error_outline,
                            color: _success
                                ? Colors.lightGreenAccent
                                : Colors.white,
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: Text(
                              _success
                                  ? 'Checkpoint berhasil dicatat'
                                  : _processing
                                      ? 'Memproses scan'
                                      : 'Scan checkpoint',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 18,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (_success) ...[
                        Text(
                          _checkpointName ?? 'Checkpoint',
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 16,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          'ID: ${_checkpointId ?? '-'}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Text(
                          'Waktu: ${_formatScannedAt(context)}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                        Text(
                          'Jarak: ${_distanceMeters?.round() ?? '-'} m'
                          '${_locationAccuracy == null ? '' : ' · Akurasi GPS ±${_locationAccuracy!.round()} m'}',
                          style: const TextStyle(color: Colors.white70),
                        ),
                      ] else
                        Text(
                          _message ??
                              'Arahkan kamera ke QR checkpoint yang terdaftar.',
                          style: const TextStyle(color: Colors.white),
                        ),
                      if (_processing) ...[
                        const SizedBox(height: 12),
                        const LinearProgressIndicator(),
                      ],
                      if (!_processing && (_success || _message != null))
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton.icon(
                            onPressed: _startNextScan,
                            icon: Icon(
                              _success ? Icons.qr_code_scanner : Icons.refresh,
                            ),
                            label: Text(
                              _success ? 'Scan berikutnya' : 'Coba lagi',
                            ),
                            style: TextButton.styleFrom(
                              foregroundColor: Colors.white,
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
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
