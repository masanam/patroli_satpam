import 'package:flutter/material.dart';
import 'package:police_patrol_app/services/auth_service.dart';
import 'package:police_patrol_app/services/firebase_service.dart';
import 'package:police_patrol_app/models/patrol_route.dart';
import 'package:police_patrol_app/views/route_detail_page.dart';
import 'dart:async';

class ReportViewPage extends StatefulWidget {
  @override
  _ReportViewPageState createState() => _ReportViewPageState();
}

class _ReportViewPageState extends State<ReportViewPage> {
  final FirebaseService _firebaseService = FirebaseService();
  List<PatrolRoute> _patrolRoutes = [];
  Map<String, int> _routeIncidentCounts = {};
  Map<String, int> _checkpointScanCounts = {};
  StreamSubscription<List<PatrolRoute>>? _routesSubscription;

  @override
  void initState() {
    super.initState();

    // Fetching patrol routes on initialization
    _routesSubscription = _firebaseService
        .getPatrolRoutesForOfficer(AuthService().currentUser!.uid)
        .listen((routes) async {
      // Sort routes based on startTime in descending order
      routes.sort((a, b) => b.startTime.compareTo(a.startTime));
      setState(() {
        _patrolRoutes = routes;
      });

      final counts = await _firebaseService.getIncidentCountsForPatrolRoutes(
          routes.map((route) => route.id).toList());
      if (!mounted) return;
      setState(() {
        _routeIncidentCounts = counts;
      });
      final scanCounts = await _firebaseService
          .getCheckpointScanCounts(routes.map((route) => route.id).toList());
      if (!mounted) return;
      setState(() => _checkpointScanCounts = scanCounts);
    });
  }

  @override
  void dispose() {
    _routesSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        title: Text('Patrol Route Reports'),
      ),
      body: Padding(
        padding: const EdgeInsets.all(8.0),
        child: ListView.builder(
          itemCount: _patrolRoutes.length,
          itemBuilder: (context, index) {
            PatrolRoute route = _patrolRoutes[index];
            final patrolDuration =
                (route.endTime ?? DateTime.now()).difference(route.startTime);
            final scanCount = _checkpointScanCounts[route.id] ?? 0;
            return Card(
              elevation: 4,
              margin: EdgeInsets.symmetric(vertical: 8),
              child: ListTile(
                contentPadding: EdgeInsets.all(16),
                leading: CircleAvatar(
                  child: Icon(Icons.map, color: Colors.white),
                  backgroundColor: Colors.blue,
                ),
                title: Text(
                  'Patrol on ${route.startTime.toLocal()}',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'End: ${route.endTime?.toLocal() ?? 'Active'} | Duration: ${patrolDuration.inMinutes} mins',
                      style: TextStyle(fontSize: 14),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Incidents: ${_routeIncidentCounts[route.id] ?? 0}',
                      style: TextStyle(fontSize: 14, color: Colors.red),
                    ),
                    SizedBox(height: 8),
                    Text(
                      'Checkpoint scans: $scanCount',
                      style: TextStyle(fontSize: 14, color: Colors.deepPurple),
                    ),
                  ],
                ),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) =>
                          RouteDetailPage(patrolRoute: _patrolRoutes[index]),
                    ),
                  );
                },
              ),
            );
          },
        ),
      ),
    );
  }
}
