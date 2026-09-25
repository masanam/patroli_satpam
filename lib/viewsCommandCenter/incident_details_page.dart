import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart' as ll;
import 'package:police_patrol_app/models/incident.dart';
import 'package:police_patrol_app/models/patrol_report.dart';
import 'package:police_patrol_app/services/firebase_service.dart';

class IncidentDetailsPage extends StatefulWidget {
  final Incident incident;

  IncidentDetailsPage({required this.incident});

  @override
  _IncidentDetailsPageState createState() => _IncidentDetailsPageState();
}

class _IncidentDetailsPageState extends State<IncidentDetailsPage> {
  final Set<fm.Marker> _markers = {};
  final FirebaseService _firebaseService = FirebaseService();
  PatrolReport? _patrolReport;

  @override
  void initState() {
    super.initState();
    _markers.add(
      fm.Marker(
        key: ValueKey(widget.incident.id),
        point: ll.LatLng(widget.incident.latitude, widget.incident.longitude),
        width: 40,
        height: 40,
        child: const Icon(Icons.warning, color: Colors.orange, size: 32),
      ),
    );

    _fetchPatrolReport(); // Fetch associated patrol report
  }

  void _fetchPatrolReport() async {
    PatrolReport? patrolReport =
        await _firebaseService.getPatrolReportByIncident(widget.incident);
    setState(() {
      _patrolReport = patrolReport;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Incident Details'),
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Description:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 5),
                      Text('${widget.incident.description}'),
                      SizedBox(height: 10),
                      Row(
                        children: [
                          Icon(Icons.location_on, color: Colors.blue),
                          SizedBox(width: 5),
                          Expanded(
                            child: Text(
                              'Latitude: ${widget.incident.latitude}, Longitude: ${widget.incident.longitude}',
                              style: TextStyle(fontSize: 14),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              SizedBox(height: 10),
              SizedBox(
                height: 200,
                child: fm.FlutterMap(
                  options: fm.MapOptions(
                    initialCenter: ll.LatLng(
                        widget.incident.latitude, widget.incident.longitude),
                    initialZoom: 15,
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
              ),
              SizedBox(height: 10),
              if (widget.incident.mediaUrl != null)
                Container(
                  height: 400,
                  width: double.infinity,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8.0),
                    child: Image.network(
                      widget.incident.mediaUrl!,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              SizedBox(height: 10),
              Card(
                elevation: 4,
                child: Padding(
                  padding: const EdgeInsets.all(10.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Incident Type:',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      SizedBox(height: 5),
                      Text('${widget.incident.type}'),
                      // ... add more details as needed ...
                    ],
                  ),
                ),
              ),
              SizedBox(height: 10),
              if (_patrolReport != null)
                Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Patrol Report',
                          style: TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 16),
                        ),
                        Divider(),
                        ListTile(
                          leading: Icon(Icons.date_range),
                          title: Text(
                              'Tanggal dan Waktu Surat Perintah: ${_patrolReport!.warrantDateTime}'),
                        ),
                        ListTile(
                          leading: Icon(Icons.running_with_errors),
                          title: Text(
                              'Tipe Patroli: ${_patrolReport!.typeOfPatrol}'),
                        ),
                        ListTile(
                          leading: Icon(Icons.nature_people),
                          title: Text(
                              'Sifat Patroli: ${_patrolReport!.natureOfPatrol}'),
                        ),
                        ListTile(
                          leading: Icon(Icons.directions_walk),
                          title: Text(
                              'Patrol on Foot?: ${_patrolReport!.isFootPatrol ? 'Yes' : 'No'}'),
                        ),
                        ListTile(
                          leading: Icon(Icons.group),
                          title: Text(
                              'Number of Personnel: ${_patrolReport!.numberOfPersonnel}'),
                        ),
                      ],
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
