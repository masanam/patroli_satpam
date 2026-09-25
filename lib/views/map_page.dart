import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart' as ll;
import 'package:location/location.dart';
import 'package:police_patrol_app/views/patrol_report_page.dart';
import 'package:police_patrol_app/views/report_page.dart';
import 'package:police_patrol_app/views/checkpoint_scanner_page.dart';
import 'package:uuid/uuid.dart';
import 'package:get/get.dart';
import 'package:flutter_speed_dial/flutter_speed_dial.dart';
import 'package:police_patrol_app/services/firebase_service.dart';
import 'package:police_patrol_app/models/incident.dart';
import 'package:police_patrol_app/models/patrol_route.dart';
import 'package:police_patrol_app/services/auth_service.dart';
import 'package:police_patrol_app/services/location_service.dart';
import 'dart:async';

class MapPage extends StatefulWidget {
  @override
  _MapPageState createState() => _MapPageState();
}

class _MapPageState extends State<MapPage> {
  final FirebaseService _firebaseService = FirebaseService();
  final fm.MapController _mapController = fm.MapController();
  StreamSubscription? _routesSubscription;
  ll.LatLng? _pendingUserLocation;
  bool _mapReady = false;

  @override
  void initState() {
    super.initState();
    if (!Get.isRegistered<MapController>()) {
      Get.put(MapController());
    }
    _loadIncidents();
    _setUserLocation();

    // Listen to patrol routes updates from Firestore in real-time
    _routesSubscription = _firebaseService
        .getPatrolRoutesForOfficer(AuthService().currentUser!.uid)
        .listen((routes) {
      final controller = Get.find<MapController>();
      for (final route in routes) {
        controller.addRouteMarkers(route);
      }
    });
  }

  Future<void> _setUserLocation() async {
    ll.LatLng? userLocation = await _getCurrentUserLocation();
    if (userLocation != null && mounted) {
      _pendingUserLocation = userLocation;
      if (_mapReady) {
        _mapController.move(userLocation, 15);
      }
    }
  }

  Future<ll.LatLng?> _getCurrentUserLocation() async {
    Location location = Location();

    bool _serviceEnabled;
    PermissionStatus _permissionGranted;
    LocationData _locationData;

    _serviceEnabled = await location.serviceEnabled();
    if (!_serviceEnabled) {
      _serviceEnabled = await location.requestService();
      if (!_serviceEnabled) {
        return null;
      }
    }

    _permissionGranted = await location.hasPermission();
    if (_permissionGranted == PermissionStatus.denied) {
      _permissionGranted = await location.requestPermission();
      if (_permissionGranted != PermissionStatus.granted) {
        return null;
      }
    }

    _locationData = await location.getLocation();
    return ll.LatLng(_locationData.latitude!, _locationData.longitude!);
  }

  Future<List<Incident>> _loadIncidents() async {
    List<Incident> incidents = await _firebaseService.getIncidents();
    if (mounted) {
      Get.find<MapController>().setIncidents(incidents);
    }
    return incidents;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.blueGrey,
        title: Text(
          'Patrol Map',
          style: const TextStyle(fontSize: 18),
        ),
      ),
      body: Stack(
        children: [
          GetBuilder<MapController>(
            builder: (controller) => fm.FlutterMap(
              mapController: _mapController,
              options: fm.MapOptions(
                initialCenter: _pendingUserLocation ?? const ll.LatLng(0, 0),
                initialZoom: _pendingUserLocation == null ? 2 : 15,
                onMapReady: () {
                  _mapReady = true;
                  final location = _pendingUserLocation;
                  if (location != null) {
                    _mapController.move(location, 15);
                  }
                },
              ),
              children: [
                fm.TileLayer(
                  urlTemplate: 'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                  userAgentPackageName: 'com.example.police_patrol_app',
                ),
                fm.PolylineLayer(polylines: controller.polylines.toList()),
                fm.MarkerLayer(markers: controller.markers.toList()),
              ],
            ),
          ),
          Positioned(
            left: 16.0,
            bottom: 16.0,
            child: GetBuilder<MapController>(
              builder: (controller) => SpeedDial(
                animatedIcon: AnimatedIcons.menu_close,
                animatedIconTheme: IconThemeData(size: 22.0),
                visible: true, // Toggle visibility of dial
                curve: Curves.bounceIn,
                overlayColor: Colors.black,
                overlayOpacity: 0.5,
                onOpen: () => print('OPENING DIAL'),
                onClose: () => print('DIAL CLOSED'),
                tooltip: 'Speed Dial',
                heroTag: 'speed-dial-hero-tag',
                backgroundColor: Colors.white,
                foregroundColor: Colors.black,
                elevation: 8.0,
                shape: CircleBorder(),
                children: [
                  SpeedDialChild(
                    child: Icon(
                        controller.isRecording ? Icons.stop : Icons.play_arrow),
                    backgroundColor:
                        controller.isRecording ? Colors.red : Colors.green,
                    label: controller.isRecording
                        ? 'Stop Recording'
                        : 'Start Recording',
                    labelStyle: TextStyle(fontSize: 18.0),
                    onTap: () {
                      if (controller.isRecording) {
                        controller.stopRecording();
                      } else {
                        controller.initiateRecording(context);
                      }
                    },
                  ),
                  SpeedDialChild(
                    child: Icon(Icons.add_alert),
                    backgroundColor: Colors.blue,
                    label: 'Report Incident',
                    labelStyle: TextStyle(fontSize: 18.0),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => ReportPage(
                              patrolRouteId: controller.currentPatrolRouteId),
                        ),
                      );
                    },
                  ),
                  SpeedDialChild(
                    child: const Icon(Icons.qr_code_scanner),
                    backgroundColor: Colors.deepPurple,
                    label: 'Scan Checkpoint',
                    labelStyle: const TextStyle(fontSize: 18.0),
                    onTap: () => controller.openCheckpointScanner(context),
                  ),
                ],
              ),
            ),
          )
        ],
      ),
    );
  }

  @override
  void dispose() {
    _routesSubscription?.cancel();
    if (Get.isRegistered<MapController>()) {
      Get.delete<MapController>();
    }
    super.dispose();
  }
}

class MapController extends GetxController {
  final FirebaseService _firebaseService = FirebaseService();
  final List<LocationPoint> _currentRoute = [];
  StreamSubscription? _locationSubscription;
  String? _currentPatrolRouteId;
  final List<Incident> _incidents = [];
  final Set<fm.Marker> markers = <fm.Marker>{};
  final Set<fm.Polyline> polylines = <fm.Polyline>{};

  // Make this public so that it can be accessed from _MapPageState
  String? get currentPatrolRouteId => _currentPatrolRouteId;

  bool isRecording = false;

  void initiateRecording(BuildContext context) {
    _currentPatrolRouteId = Uuid().v1(); // Generate the ID here
    // Navigate to PatrolReportPage and start recording if the report is valid
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => PatrolReportPage(
          onReportSubmitted: () {
            startRecording();
          },
          patrolRouteId: _currentPatrolRouteId, // Pass the ID directly
        ),
      ),
    );
  }

  void startRecording() {
    isRecording = true;
    update();
    _startRouteRecording();
  }

  Future<void> openCheckpointScanner(BuildContext context) async {
    final user = AuthService().currentUser;
    if (user == null) {
      Get.snackbar('Checkpoint', 'Silakan login kembali.');
      return;
    }
    final sessionId = _currentPatrolRouteId ??
        await _firebaseService.createCheckpointSession(user.uid);
    _currentPatrolRouteId ??= sessionId;
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => CheckpointScannerPage(sessionId: sessionId),
      ),
    );
  }

  void stopRecording() {
    isRecording = false;
    update();
    _stopRouteRecording();
  }

  void toggleRecording() {
    isRecording = !isRecording;
    update();
    if (isRecording) {
      _startRouteRecording();
    } else {
      _stopRouteRecording();
    }
  }

  void setIncidents(List<Incident> incidents) {
    final previousIncidentIds = _incidents.map((incident) => incident.id);
    markers.removeWhere((marker) {
      final key = marker.key;
      return key is ValueKey<String> && previousIncidentIds.contains(key.value);
    });
    _incidents
      ..clear()
      ..addAll(incidents);
    _updateIncidentMarkers();
    update();
  }

  void addRouteMarkers(PatrolRoute route) {
    if (route.locations.isEmpty) return;
    markers.add(fm.Marker(
      key: ValueKey('start_${route.id}'),
      point: ll.LatLng(
          route.locations.first.latitude, route.locations.first.longitude),
      width: 40,
      height: 40,
      child: const Icon(Icons.flag, color: Colors.green, size: 32),
    ));
    markers.add(fm.Marker(
      key: ValueKey('end_${route.id}'),
      point: ll.LatLng(
          route.locations.last.latitude, route.locations.last.longitude),
      width: 40,
      height: 40,
      child: const Icon(Icons.flag, color: Colors.red, size: 32),
    ));
    update();
  }

  void _updateIncidentMarkers() {
    markers.addAll(_incidents.map((incident) {
      return fm.Marker(
        key: ValueKey(incident.id),
        point: ll.LatLng(incident.latitude, incident.longitude),
        width: 40,
        height: 40,
        child: const Icon(Icons.warning, color: Colors.orange, size: 32),
      );
    }));
  }

  void _startRouteRecording() {
    _locationSubscription?.cancel();
    _currentRoute.clear();
    _locationSubscription = LocationService().locationStream.listen((location) {
      if (location.latitude != null && location.longitude != null) {
        _currentRoute.add(LocationPoint(
          latitude: location.latitude!,
          longitude: location.longitude!,
          timestamp: DateTime.now(),
        ));
      } else {
        // Handle the case where latitude or longitude is null, if needed
      }
    });
  }

  void _stopRouteRecording() {
    _locationSubscription?.cancel();
    _locationSubscription = null;
    final routeId = _currentPatrolRouteId;
    final user = AuthService().currentUser;
    if (routeId == null || user == null) {
      Get.snackbar(
        'Route Recording',
        'Unable to save route. Please login again.',
      );
      return;
    }
    if (_currentRoute.isNotEmpty) {
      PatrolRoute patrolRoute = PatrolRoute(
        id: routeId,
        officerId: user.uid,
        startTime: _currentRoute.first.timestamp,
        endTime: _currentRoute.last.timestamp,
        locations: _currentRoute,
      );
      _firebaseService.addPatrolRoute(patrolRoute).then((_) {
        // Using Get's built-in snackbar for displaying messages
        Get.snackbar('Route Recording', 'Route recording stopped and saved.');
        addRouteMarkers(patrolRoute);
      }).catchError((error) {
        Get.snackbar(
            'Route Recording', 'Error saving route. Please try again.');
      });
    } else {
      Get.snackbar('Route Recording', 'No route recorded.');
    }
    _currentPatrolRouteId = null; // Reset the current patrol route ID
  }

  @override
  void onClose() {
    _locationSubscription?.cancel();
    super.onClose();
  }
}
