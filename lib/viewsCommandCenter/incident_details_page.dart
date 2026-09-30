import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart' as ll;
import 'package:police_patrol_app/models/incident.dart';
import 'package:police_patrol_app/models/patrol_report.dart';
import 'package:police_patrol_app/services/firebase_service.dart';

class IncidentDetailsPage extends StatefulWidget {
  final Incident incident;

  const IncidentDetailsPage({Key? key, required this.incident}) : super(key: key);

  @override
  _IncidentDetailsPageState createState() => _IncidentDetailsPageState();
}

class _IncidentDetailsPageState extends State<IncidentDetailsPage> {
  final Set<fm.Marker> _markers = {};
  final FirebaseService _firebaseService = FirebaseService();
  PatrolReport? _patrolReport;
  bool _isLoadingReport = true;

  @override
  void initState() {
    super.initState();
    _markers.add(
      fm.Marker(
        key: ValueKey(widget.incident.id),
        point: ll.LatLng(widget.incident.latitude, widget.incident.longitude),
        width: 40,
        height: 40,
        child: const Icon(Icons.location_on, color: Colors.red, size: 40),
      ),
    );

    _fetchPatrolReport();
  }

  void _fetchPatrolReport() async {
    try {
      PatrolReport? patrolReport =
          await _firebaseService.getPatrolReportByIncident(widget.incident);
      if (mounted) {
        setState(() {
          _patrolReport = patrolReport;
          _isLoadingReport = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _isLoadingReport = false;
        });
      }
    }
  }

  Color _getStatusColor(IncidentStatus? status) {
    switch (status) {
      case IncidentStatus.Pending:
        return Colors.red;
      case IncidentStatus.Resolved:
        return Colors.green;
      case IncidentStatus.InProgress:
        return Colors.orange;
      default:
        return Colors.blue;
    }
  }

  @override
  Widget build(BuildContext context) {
    final statusColor = _getStatusColor(widget.incident.status);

    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Detail Insiden', style: TextStyle(fontWeight: FontWeight.bold)),
        elevation: 0,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Map Header
            SizedBox(
              height: 250,
              child: Stack(
                children: [
                  fm.FlutterMap(
                    options: fm.MapOptions(
                      initialCenter: ll.LatLng(
                          widget.incident.latitude, widget.incident.longitude),
                      initialZoom: 16,
                      interactionOptions: const fm.InteractionOptions(
                        flags: fm.InteractiveFlag.all & ~fm.InteractiveFlag.rotate,
                      ),
                    ),
                    children: [
                      fm.TileLayer(
                        urlTemplate:
                            'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                        userAgentPackageName: 'com.example.police_patrol_app',
                      ),
                      fm.MarkerLayer(markers: _markers.toList()),
                    ],
                  ),
                  // Gradient Overlay at bottom of map
                  Positioned(
                    bottom: 0,
                    left: 0,
                    right: 0,
                    height: 80,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.bottomCenter,
                          end: Alignment.topCenter,
                          colors: [
                            Colors.grey.shade100.withOpacity(1),
                            Colors.grey.shade100.withOpacity(0),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),

            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Main Info Card
                  Transform.translate(
                    offset: const Offset(0, -30),
                    child: Card(
                      elevation: 4,
                      shadowColor: Colors.black12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(16.0),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Text(
                                    widget.incident.type ?? 'Insiden Tanpa Kategori',
                                    style: const TextStyle(
                                      fontSize: 20,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.black87,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 12, vertical: 6),
                                  decoration: BoxDecoration(
                                    color: statusColor.withOpacity(0.1),
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(color: statusColor.withOpacity(0.5)),
                                  ),
                                  child: Text(
                                    widget.incident.status?.toString().split('.').last ??
                                        'Unknown',
                                    style: TextStyle(
                                      color: statusColor,
                                      fontWeight: FontWeight.bold,
                                      fontSize: 12,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            const Text(
                              'Deskripsi Kejadian',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 8),
                            Text(
                              widget.incident.description,
                              style: const TextStyle(
                                fontSize: 16,
                                height: 1.5,
                                color: Colors.black87,
                              ),
                            ),
                            const Divider(height: 32),
                            Row(
                              children: [
                                Icon(Icons.access_time,
                                    size: 20, color: Colors.grey.shade600),
                                const SizedBox(width: 8),
                                Text(
                                  "${widget.incident.timestamp.day.toString().padLeft(2, '0')}/${widget.incident.timestamp.month.toString().padLeft(2, '0')}/${widget.incident.timestamp.year} ${widget.incident.timestamp.hour.toString().padLeft(2, '0')}:${widget.incident.timestamp.minute.toString().padLeft(2, '0')}",
                                  style: TextStyle(
                                    fontSize: 14,
                                    color: Colors.grey.shade800,
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),
                            Row(
                              children: [
                                Icon(Icons.location_on_outlined,
                                    size: 20, color: Colors.grey.shade600),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Lat: ${widget.incident.latitude.toStringAsFixed(5)}, Lng: ${widget.incident.longitude.toStringAsFixed(5)}',
                                    style: TextStyle(
                                      fontSize: 14,
                                      color: Colors.grey.shade800,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  // Media Section
                  if (widget.incident.mediaUrl != null &&
                      widget.incident.mediaUrl!.isNotEmpty) ...[
                    const Padding(
                      padding: EdgeInsets.only(left: 4, bottom: 12),
                      child: Text(
                        'Lampiran Media',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                    ),
                    Card(
                      elevation: 2,
                      shadowColor: Colors.black12,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      clipBehavior: Clip.antiAlias,
                      child: Image.network(
                        widget.incident.mediaUrl!,
                        width: double.infinity,
                        height: 250,
                        fit: BoxFit.cover,
                        loadingBuilder: (context, child, loadingProgress) {
                          if (loadingProgress == null) return child;
                          return SizedBox(
                            height: 250,
                            child: Center(
                              child: CircularProgressIndicator(
                                value: loadingProgress.expectedTotalBytes != null
                                    ? loadingProgress.cumulativeBytesLoaded /
                                        loadingProgress.expectedTotalBytes!
                                    : null,
                              ),
                            ),
                          );
                        },
                        errorBuilder: (context, error, stackTrace) {
                          return Container(
                            height: 200,
                            color: Colors.grey.shade200,
                            child: const Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(Icons.broken_image, size: 48, color: Colors.grey),
                                SizedBox(height: 8),
                                Text('Gagal memuat gambar',
                                    style: TextStyle(color: Colors.grey)),
                              ],
                            ),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],

                  // Patrol Report Section
                  const Padding(
                    padding: EdgeInsets.only(left: 4, bottom: 12),
                    child: Text(
                      'Laporan Patroli Terkait',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.black87,
                      ),
                    ),
                  ),
                  _isLoadingReport
                      ? const Center(child: Padding(
                          padding: EdgeInsets.all(32.0),
                          child: CircularProgressIndicator(),
                        ))
                      : _patrolReport == null
                          ? Card(
                              elevation: 0,
                              color: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                                side: BorderSide(color: Colors.grey.shade300),
                              ),
                              child: const Padding(
                                padding: EdgeInsets.all(24.0),
                                child: Center(
                                  child: Text(
                                    'Tidak ada laporan patroli yang terkait dengan insiden ini.',
                                    textAlign: TextAlign.center,
                                    style: TextStyle(color: Colors.grey),
                                  ),
                                ),
                              ),
                            )
                          : Card(
                              elevation: 2,
                              shadowColor: Colors.black12,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(16),
                              ),
                              child: Column(
                                children: [
                                  _buildReportTile(
                                    icon: Icons.date_range,
                                    title: 'Waktu Surat Perintah',
                                    value: _formatReportDate(_patrolReport!.warrantDateTime),
                                  ),
                                  const Divider(height: 1),
                                  _buildReportTile(
                                    icon: Icons.local_police_outlined,
                                    title: 'Tipe Patroli',
                                    value: _patrolReport!.typeOfPatrol,
                                  ),
                                  const Divider(height: 1),
                                  _buildReportTile(
                                    icon: Icons.nature_people_outlined,
                                    title: 'Sifat Patroli',
                                    value: _patrolReport!.natureOfPatrol,
                                  ),
                                  const Divider(height: 1),
                                  _buildReportTile(
                                    icon: Icons.directions_walk,
                                    title: 'Patroli Jalan Kaki',
                                    value: _patrolReport!.isFootPatrol ? 'Ya' : 'Tidak',
                                  ),
                                  const Divider(height: 1),
                                  _buildReportTile(
                                    icon: Icons.group_outlined,
                                    title: 'Jumlah Personel',
                                    value: '${_patrolReport!.numberOfPersonnel} Orang',
                                  ),
                                ],
                              ),
                            ),
                  const SizedBox(height: 40),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildReportTile({required IconData icon, required String title, required String value}) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 12.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue.withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Icon(icon, color: Colors.blue.shade700, size: 20),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  value,
                  style: const TextStyle(
                    fontSize: 15,
                    color: Colors.black87,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  String _formatReportDate(DateTime dt) {
    return "${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} ${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}";
  }
}
