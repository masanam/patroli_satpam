import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart' as ll;
import 'package:police_patrol_app/models/incident.dart';
import 'package:police_patrol_app/models/patrol_route.dart';
import 'package:police_patrol_app/services/firebase_service.dart';

class RouteDetailPage extends StatefulWidget {
  const RouteDetailPage({super.key, required this.patrolRoute});
  final PatrolRoute patrolRoute;

  @override
  State<RouteDetailPage> createState() => _RouteDetailPageState();
}

class _RouteDetailPageState extends State<RouteDetailPage> {
  final _firebaseService = FirebaseService();
  final _mapController = fm.MapController();
  List<Incident> _incidents = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadIncidents();
  }

  Future<void> _loadIncidents() async {
    try {
      final incidents = await _firebaseService
          .getIncidentsForPatrolRoute(widget.patrolRoute.id);
      if (mounted) setState(() => _incidents = incidents);
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final route = widget.patrolRoute;
    final hasGps = route.locations.isNotEmpty;
    final duration =
        (route.endTime ?? DateTime.now()).difference(route.startTime);
    final distanceMeters = _routeDistance(route.locations);
    final averageSpeed = duration.inSeconds == 0
        ? 0.0
        : (distanceMeters / 1000) / (duration.inSeconds / 3600);

    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F4),
      appBar: AppBar(
        title: const Text('Detail rute'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.blueGrey.shade900,
        elevation: 0,
      ),
      body: RefreshIndicator(
        onRefresh: _loadIncidents,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
          children: [
            _RouteHeader(isActive: route.endTime == null, routeId: route.id),
            const SizedBox(height: 16),
            _GpsMap(
              mapController: _mapController,
              locations: route.locations,
              incidents: _incidents,
            ),
            const SizedBox(height: 16),
            Text('Ringkasan patroli',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                _MetricCard(
                    icon: Icons.route_outlined,
                    label: 'Jarak',
                    value: hasGps ? _formatDistance(distanceMeters) : '—'),
                _MetricCard(
                    icon: Icons.timer_outlined,
                    label: 'Durasi',
                    value: _formatDuration(duration)),
                _MetricCard(
                    icon: Icons.speed_outlined,
                    label: 'Rata-rata',
                    value: hasGps
                        ? '${averageSpeed.toStringAsFixed(1)} km/j'
                        : '—'),
                _MetricCard(
                    icon: Icons.location_searching_outlined,
                    label: 'Titik GPS',
                    value: '${route.locations.length}'),
              ],
            ),
            const SizedBox(height: 20),
            _SectionCard(
              title: 'Informasi rute',
              icon: Icons.info_outline,
              child: Column(children: [
                _InfoRow('ID rute', route.id),
                _InfoRow('Petugas', route.officerId),
                _InfoRow('Mulai', _formatDateTime(route.startTime)),
                _InfoRow(
                    'Selesai',
                    route.endTime == null
                        ? 'Patroli sedang berlangsung'
                        : _formatDateTime(route.endTime!)),
                _InfoRow(
                    'Status GPS',
                    hasGps
                        ? 'Terekam (${route.locations.length} titik)'
                        : 'Belum ada data GPS'),
                if (hasGps)
                  _InfoRow(
                      'Koordinat terakhir', _coordinate(route.locations.last)),
              ]),
            ),
            const SizedBox(height: 20),
            Text('Aktivitas & insiden',
                style: Theme.of(context)
                    .textTheme
                    .titleLarge
                    ?.copyWith(fontWeight: FontWeight.w700)),
            const SizedBox(height: 6),
            Text(
                hasGps && _incidents.isEmpty
                    ? 'Menampilkan data contoh dari titik GPS karena belum ada laporan insiden.'
                    : 'Laporan yang terhubung dengan rute ini.',
                style: const TextStyle(color: Colors.blueGrey)),
            const SizedBox(height: 10),
            if (_isLoading)
              const Center(
                  child: Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator()))
            else if (_incidents.isNotEmpty)
              ..._incidents.map((incident) => _IncidentCard(
                  incident: incident,
                  onTap: () => _mapController.move(
                      ll.LatLng(incident.latitude, incident.longitude), 16)))
            else if (hasGps)
              ..._dummyActivities(route.locations)
                  .map((activity) => _ActivityCard(activity: activity))
            else
              const _EmptyState(),
          ],
        ),
      ),
    );
  }

  List<_RouteActivity> _dummyActivities(List<LocationPoint> points) {
    final indexes = <int>{0, points.length ~/ 2, points.length - 1}.toList()
      ..sort();
    const labels = [
      'Patroli dimulai',
      'Pemeriksaan area',
      'Posisi GPS terakhir'
    ];
    const icons = [
      Icons.play_circle_outline,
      Icons.fact_check_outlined,
      Icons.location_on_outlined
    ];
    return List.generate(indexes.length, (i) {
      final point = points[indexes[i]];
      return _RouteActivity(
          labels[i],
          'Titik GPS ${indexes[i] + 1} · ${_coordinate(point)}',
          point.timestamp,
          icons[i]);
    });
  }

  double _routeDistance(List<LocationPoint> locations) {
    if (locations.length < 2) return 0;
    const distance = ll.Distance();
    var total = 0.0;
    for (var i = 1; i < locations.length; i++) {
      total += distance(
          ll.LatLng(locations[i - 1].latitude, locations[i - 1].longitude),
          ll.LatLng(locations[i].latitude, locations[i].longitude));
    }
    return total;
  }

  String _coordinate(LocationPoint point) =>
      '${point.latitude.toStringAsFixed(5)}, ${point.longitude.toStringAsFixed(5)}';
  String _formatDistance(double meters) => meters >= 1000
      ? '${(meters / 1000).toStringAsFixed(2)} km'
      : '${meters.round()} m';
  String _formatDuration(Duration value) => value.inHours > 0
      ? '${value.inHours}j ${value.inMinutes.remainder(60)}m'
      : '${value.inMinutes} menit';
  String _formatDateTime(DateTime value) =>
      '${value.day.toString().padLeft(2, '0')}/${value.month.toString().padLeft(2, '0')}/${value.year} · ${value.hour.toString().padLeft(2, '0')}:${value.minute.toString().padLeft(2, '0')}';
}

class _RouteHeader extends StatelessWidget {
  const _RouteHeader({required this.isActive, required this.routeId});
  final bool isActive;
  final String routeId;
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
            color: Colors.blueGrey.shade800,
            borderRadius: BorderRadius.circular(12)),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            const Icon(Icons.local_police_outlined, color: Colors.white),
            const SizedBox(width: 10),
            Expanded(
                child: Text('Sesi patroli',
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        color: Colors.white, fontWeight: FontWeight.w700))),
            _StatusPill(active: isActive),
          ]),
          const SizedBox(height: 12),
          Text(
              'Rute #${routeId.length > 12 ? routeId.substring(0, 12) : routeId}',
              style: TextStyle(color: Colors.blueGrey.shade100)),
        ]),
      );
}

class _GpsMap extends StatelessWidget {
  const _GpsMap(
      {required this.mapController,
      required this.locations,
      required this.incidents});
  final fm.MapController mapController;
  final List<LocationPoint> locations;
  final List<Incident> incidents;
  @override
  Widget build(BuildContext context) {
    if (locations.isEmpty) return const _NoGpsMap();
    final points =
        locations.map((p) => ll.LatLng(p.latitude, p.longitude)).toList();
    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: SizedBox(
          height: 265,
          child: fm.FlutterMap(
            mapController: mapController,
            options:
                fm.MapOptions(initialCenter: points.first, initialZoom: 15),
            children: [
              fm.TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.police_patrol_app'),
              fm.PolylineLayer(polylines: [
                fm.Polyline(
                    points: points, color: Colors.blue.shade700, strokeWidth: 4)
              ]),
              fm.MarkerLayer(markers: [
                fm.Marker(
                    point: points.first,
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.trip_origin,
                        color: Colors.green, size: 28)),
                fm.Marker(
                    point: points.last,
                    width: 42,
                    height: 42,
                    child: const Icon(Icons.flag, color: Colors.red, size: 32)),
                ...incidents.map((i) => fm.Marker(
                    point: ll.LatLng(i.latitude, i.longitude),
                    width: 40,
                    height: 40,
                    child: const Icon(Icons.warning_amber_rounded,
                        color: Colors.orange, size: 31))),
              ]),
            ],
          )),
    );
  }
}

class _NoGpsMap extends StatelessWidget {
  const _NoGpsMap();
  @override
  Widget build(BuildContext context) => Container(
      height: 180,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
          color: Colors.blueGrey.shade50,
          borderRadius: BorderRadius.circular(12)),
      child:
          const Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Icon(Icons.gps_off_outlined, size: 38, color: Colors.blueGrey),
        SizedBox(height: 8),
        Text('Rute GPS belum direkam',
            style: TextStyle(fontWeight: FontWeight.w600)),
        SizedBox(height: 4),
        Text(
            'Peta dan data perjalanan tampil setelah GPS menerima titik lokasi.',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.blueGrey))
      ]));
}

class _MetricCard extends StatelessWidget {
  const _MetricCard(
      {required this.icon, required this.label, required this.value});
  final IconData icon;
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => SizedBox(
      width: (MediaQuery.sizeOf(context).width - 42) / 2,
      child: Card(
          margin: EdgeInsets.zero,
          elevation: 0,
          color: Colors.white,
          child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(icon, color: Colors.blueGrey.shade700),
                    const SizedBox(height: 12),
                    Text(value,
                        style: Theme.of(context)
                            .textTheme
                            .titleMedium
                            ?.copyWith(fontWeight: FontWeight.w700)),
                    Text(label, style: const TextStyle(color: Colors.blueGrey))
                  ]))));
}

class _SectionCard extends StatelessWidget {
  const _SectionCard(
      {required this.title, required this.icon, required this.child});
  final String title;
  final IconData icon;
  final Widget child;
  @override
  Widget build(BuildContext context) => Card(
      margin: EdgeInsets.zero,
      elevation: 0,
      child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Icon(icon, color: Colors.blueGrey.shade700),
              const SizedBox(width: 8),
              Text(title,
                  style: Theme.of(context)
                      .textTheme
                      .titleMedium
                      ?.copyWith(fontWeight: FontWeight.w700))
            ]),
            const SizedBox(height: 10),
            child
          ])));
}

class _InfoRow extends StatelessWidget {
  const _InfoRow(this.label, this.value);
  final String label;
  final String value;
  @override
  Widget build(BuildContext context) => Padding(
      padding: const EdgeInsets.symmetric(vertical: 7),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        SizedBox(
            width: 116,
            child: Text(label, style: const TextStyle(color: Colors.blueGrey))),
        Expanded(
            child: Text(value,
                style: const TextStyle(fontWeight: FontWeight.w600)))
      ]));
}

class _StatusPill extends StatelessWidget {
  const _StatusPill({required this.active});
  final bool active;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
          color: active ? Colors.green.shade600 : Colors.blueGrey.shade600,
          borderRadius: BorderRadius.circular(20)),
      child: Text(active ? 'Aktif' : 'Selesai',
          style: const TextStyle(
              color: Colors.white, fontSize: 12, fontWeight: FontWeight.w600)));
}

class _IncidentCard extends StatelessWidget {
  const _IncidentCard({required this.incident, required this.onTap});
  final Incident incident;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) => Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
          onTap: onTap,
          leading: const CircleAvatar(
              backgroundColor: Color(0xFFFFF3E0),
              child: Icon(Icons.warning_amber_rounded, color: Colors.orange)),
          title: Text(incident.description,
              maxLines: 1, overflow: TextOverflow.ellipsis),
          subtitle: Text(
              '${incident.type ?? 'Insiden'} · ${incident.timestamp.toLocal()}'),
          trailing: const Icon(Icons.chevron_right)));
}

class _RouteActivity {
  const _RouteActivity(this.title, this.detail, this.time, this.icon);
  final String title;
  final String detail;
  final DateTime time;
  final IconData icon;
}

class _ActivityCard extends StatelessWidget {
  const _ActivityCard({required this.activity});
  final _RouteActivity activity;
  @override
  Widget build(BuildContext context) => Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
          leading: CircleAvatar(
              backgroundColor: Colors.blueGrey.shade50,
              child: Icon(activity.icon, color: Colors.blueGrey.shade700)),
          title: Text(activity.title),
          subtitle: Text('${activity.detail}\n${activity.time.toLocal()}'),
          isThreeLine: true));
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();
  @override
  Widget build(BuildContext context) => const Padding(
      padding: EdgeInsets.symmetric(vertical: 28),
      child: Center(
          child: Column(children: [
        Icon(Icons.inbox_outlined, size: 36, color: Colors.blueGrey),
        SizedBox(height: 8),
        Text('Belum ada insiden atau titik GPS pada rute ini.',
            style: TextStyle(color: Colors.blueGrey))
      ])));
}
