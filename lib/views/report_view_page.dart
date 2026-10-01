import 'package:flutter/material.dart';
import 'package:latlong2/latlong.dart' as ll;
import 'package:police_patrol_app/services/auth_service.dart';
import 'package:police_patrol_app/services/firebase_service.dart';
import 'package:police_patrol_app/models/patrol_route.dart';
import 'package:police_patrol_app/models/patrol_report.dart';
import 'package:police_patrol_app/views/route_detail_page.dart';
import 'dart:async';

class ReportViewPage extends StatefulWidget {
  @override
  _ReportViewPageState createState() => _ReportViewPageState();
}

class _ReportViewPageState extends State<ReportViewPage> {
  final FirebaseService _firebaseService = FirebaseService();
  List<PatrolRoute> _patrolRoutes = [];
  List<PatrolReport> _patrolReports = [];
  Map<String, int> _routeIncidentCounts = {};
  Map<String, int> _checkpointScanCounts = {};
  StreamSubscription<List<PatrolRoute>>? _routesSubscription;
  StreamSubscription<List<PatrolReport>>? _reportsSubscription;
  bool _loadingRoutes = true;

  @override
  void initState() {
    super.initState();

    // Fetching patrol routes on initialization
    final officerId = AuthService().currentUser!.uid;
    _routesSubscription = _firebaseService
        .getPatrolRoutesForOfficer(officerId)
        .listen((routes) async {
      routes.sort((a, b) => b.startTime.compareTo(a.startTime));
      if (!mounted) return;
      setState(() {
        _patrolRoutes = routes;
        _loadingRoutes = false;
      });

      final counts = await _firebaseService.getIncidentCountsForPatrolRoutes(
          routes.map((route) => route.id).toList());
      if (!mounted) return;
      setState(() {
        _routeIncidentCounts = counts;
      });

      final routeIds = routes.map((route) => route.id).toList();
      final scanCounts =
          await _firebaseService.getCheckpointScanCounts(routeIds);
      if (!mounted) return;
      setState(() {
        _checkpointScanCounts = scanCounts;
      });
    });

    _reportsSubscription = _firebaseService
        .getPatrolReportsForOfficer(officerId)
        .listen((reports) {
      if (mounted) setState(() => _patrolReports = reports);
    });
  }

  @override
  void dispose() {
    _routesSubscription?.cancel();
    _reportsSubscription?.cancel();
    super.dispose();
  }

  PatrolReport? _reportForRoute(String routeId) {
    for (final report in _patrolReports) {
      if (report.patrolRouteId == routeId) return report;
    }
    return null;
  }

  /// Hitung total jarak rute dalam meter menggunakan Haversine
  double _calcDistance(List<LocationPoint> locs) {
    if (locs.length < 2) return 0;
    const dist = ll.Distance();
    var total = 0.0;
    for (var i = 1; i < locs.length; i++) {
      total += dist(
        ll.LatLng(locs[i - 1].latitude, locs[i - 1].longitude),
        ll.LatLng(locs[i].latitude, locs[i].longitude),
      );
    }
    return total;
  }

  String _formatDistance(double meters) => meters >= 1000
      ? '${(meters / 1000).toStringAsFixed(2)} km'
      : '${meters.round()} m';

  String _formatDateTime(BuildContext context, DateTime value) {
    final local = value.toLocal();
    final date = MaterialLocalizations.of(context).formatMediumDate(local);
    final time = TimeOfDay.fromDateTime(local).format(context);
    return '$date, $time';
  }

  String _formatDuration(Duration duration) {
    if (duration.inHours > 0) {
      return '${duration.inHours} jam ${duration.inMinutes.remainder(60)} menit';
    }
    return '${duration.inMinutes} menit';
  }

  Widget _detailRow(String label, String value, {IconData? icon}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (icon != null) ...[
            Icon(icon, size: 18, color: Colors.blueGrey),
            const SizedBox(width: 10),
          ],
          SizedBox(
            width: icon == null ? 116 : 106,
            child: Text(
              label,
              style: const TextStyle(color: Colors.blueGrey),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? 'Belum diisi' : value,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        title: const Text('Patrol Route Reports'),
      ),
      body: _loadingRoutes
          ? const Center(child: CircularProgressIndicator())
          : _patrolRoutes.isEmpty
              ? const Center(
                  child: Padding(
                    padding: EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.route_outlined, size: 48, color: Colors.blueGrey),
                        SizedBox(height: 12),
                        Text(
                          'Belum ada data patroli.',
                          textAlign: TextAlign.center,
                          style: TextStyle(color: Colors.blueGrey, fontSize: 15),
                        ),
                      ],
                    ),
                  ),
                )
              : ListView.builder(
                  padding: const EdgeInsets.all(16),
                  itemCount: _patrolRoutes.length,
                  itemBuilder: (context, index) {
                    final route = _patrolRoutes[index];
                    final report = _reportForRoute(route.id);
                    final duration = (route.endTime ?? DateTime.now())
                        .difference(route.startTime);
                    final incidentCount = _routeIncidentCounts[route.id] ?? 0;
                    final scanCount = _checkpointScanCounts[route.id] ?? 0;
                    final hasGps = route.locations.isNotEmpty;
                    final distMeters = _calcDistance(route.locations);
                    final avgSpeed = hasGps && duration.inSeconds > 0
                        ? (distMeters / 1000) / (duration.inSeconds / 3600)
                        : 0.0;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      clipBehavior: Clip.antiAlias,
                      child: ExpansionTile(
                        leading: CircleAvatar(
                          backgroundColor: route.endTime == null
                              ? Colors.orange.shade100
                              : Colors.teal.shade100,
                          child: Icon(
                            route.endTime == null
                                ? Icons.route
                                : Icons.route_outlined,
                            color: Colors.blueGrey.shade800,
                          ),
                        ),
                        title: Text(
                          report?.typeOfPatrol.isNotEmpty == true
                              ? report!.typeOfPatrol
                              : 'Patroli',
                          style: const TextStyle(fontWeight: FontWeight.w700),
                        ),
                        subtitle: Text(
                          '${_formatDateTime(context, route.startTime)} · '
                          '${route.endTime == null ? 'Aktif' : 'Selesai'}',
                        ),
                        childrenPadding:
                            const EdgeInsets.fromLTRB(16, 0, 16, 12),
                        children: [
                          const Divider(height: 1),
                          const SizedBox(height: 8),
                          _detailRow(
                            'Mulai',
                            _formatDateTime(context, route.startTime),
                            icon: Icons.play_circle_outline,
                          ),
                          _detailRow(
                            'Selesai',
                            route.endTime == null
                                ? 'Masih berlangsung'
                                : _formatDateTime(context, route.endTime!),
                            icon: Icons.stop_circle_outlined,
                          ),
                          _detailRow(
                            'Durasi',
                            _formatDuration(duration),
                            icon: Icons.timer_outlined,
                          ),
                          _detailRow(
                            'Titik GPS',
                            hasGps ? '${route.locations.length} titik' : '—',
                            icon: Icons.location_on_outlined,
                          ),
                          _detailRow(
                            'Jarak',
                            hasGps ? _formatDistance(distMeters) : '—',
                            icon: Icons.route_outlined,
                          ),
                          _detailRow(
                            'Rata-rata',
                            hasGps
                                ? '${avgSpeed.toStringAsFixed(1)} km/j'
                                : '—',
                            icon: Icons.speed_outlined,
                          ),
                          _detailRow(
                            'Insiden',
                            '$incidentCount',
                            icon: Icons.warning_amber_outlined,
                          ),
                          _detailRow(
                            'Checkpoint',
                            '$scanCount scan',
                            icon: Icons.qr_code_scanner,
                          ),
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Detail surat perintah',
                              style: Theme.of(context)
                                  .textTheme
                                  .titleSmall
                                  ?.copyWith(fontWeight: FontWeight.bold),
                            ),
                          ),
                          if (report == null)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 8),
                              child: Align(
                                alignment: Alignment.centerLeft,
                                child: Text(
                                  'Belum ada patrol report yang terhubung.',
                                  style: TextStyle(color: Colors.blueGrey),
                                ),
                              ),
                            )
                          else ...[
                            _detailRow(
                              'Tanggal surat',
                              _formatDateTime(context, report.warrantDateTime),
                            ),
                            _detailRow('Jenis patroli', report.typeOfPatrol),
                            _detailRow('Sifat patroli', report.natureOfPatrol),
                            _detailRow(
                              'Personel',
                              '${report.numberOfPersonnel} orang',
                            ),
                            _detailRow(
                              'Metode',
                              report.isFootPatrol ? 'Jalan kaki' : 'Kendaraan',
                            ),
                          ],
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () => Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (_) =>
                                      RouteDetailPage(patrolRoute: route),
                                ),
                              ),
                              icon: const Icon(Icons.open_in_new),
                              label: const Text('Buka detail rute'),
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
    );
  }
}
