import 'package:flutter/material.dart';
import 'package:police_patrol_app/models/patrol_route.dart';
import 'package:police_patrol_app/services/firebase_service.dart';
import 'package:police_patrol_app/models/user.dart';
import 'package:police_patrol_app/models/incident.dart';
import 'package:flutter_map/flutter_map.dart' as fm;
import 'package:latlong2/latlong.dart' as ll;
import 'package:video_player/video_player.dart';

class RouteDetailPage extends StatefulWidget {
  final PatrolRoute patrolRoute;

  RouteDetailPage({required this.patrolRoute});

  @override
  _RouteDetailPageState createState() => _RouteDetailPageState();
}

class _RouteDetailPageState extends State<RouteDetailPage> {
  final FirebaseService _firebaseService = FirebaseService();
  final Set<fm.Marker> _markers = {};
  final Set<fm.Polyline> _polylines = {};
  DateTime? _selectedDate;
  String? _selectedIncidentType;
  String _searchQuery = '';
  String _selectedSortOrder = 'Date (Newest First)';

  List<Incident> _incidents = [];

  // List of sorting options for demonstration purposes
  List<String> _sortOptions = ['Date (Newest First)', 'Date (Oldest First)'];

  // List of incident types for demonstration purposes
  List<String> _incidentTypes = ['All Types', 'Theft', 'Assault', 'Accident'];

  @override
  void initState() {
    super.initState();
    _initMapElements();
    _fetchIncidentsForRoute();
  }

  void _fetchIncidentsForRoute() async {
    List<Incident> incidents = await _firebaseService
        .getIncidentsForPatrolRoute(widget.patrolRoute.id);
    if (!mounted) return;
    setState(() => _incidents = incidents);
    _initMapElements(); // re-initialize map elements
  }

  void _initMapElements() {
    _markers.clear();
    _polylines.clear();
    _markers.add(fm.Marker(
      key: const ValueKey('start'),
      point: ll.LatLng(widget.patrolRoute.locations.first.latitude,
          widget.patrolRoute.locations.first.longitude),
      width: 40,
      height: 40,
      child: const Icon(Icons.flag, color: Colors.green, size: 32),
    ));
    _markers.add(fm.Marker(
      key: const ValueKey('end'),
      point: ll.LatLng(widget.patrolRoute.locations.last.latitude,
          widget.patrolRoute.locations.last.longitude),
      width: 40,
      height: 40,
      child: const Icon(Icons.flag, color: Colors.red, size: 32),
    ));

    _polylines.add(fm.Polyline(
      points: widget.patrolRoute.locations
          .map((loc) => ll.LatLng(loc.latitude, loc.longitude))
          .toList(),
      color: Colors.blue,
      strokeWidth: 4,
    ));

    for (final incident in _incidents) {
      _markers.add(fm.Marker(
        key: ValueKey(incident.id),
        point: ll.LatLng(incident.latitude, incident.longitude),
        width: 40,
        height: 40,
        child: const Icon(Icons.warning, color: Colors.orange, size: 32),
      ));
    }
  }

  void _zoomToIncident(Incident incident) {
    // The incident list remains the source of truth; the map is fitted to the route.
  }

  void _viewMedia(String mediaUrl, String mediaType) {
    Navigator.push(
        context,
        MaterialPageRoute(
            builder: (context) =>
                FullScreenMediaView(mediaUrl: mediaUrl, mediaType: mediaType)));
  }

  void _selectDate(BuildContext context) async {
    DateTime? pickedDate = await showDatePicker(
      context: context,
      initialDate: DateTime.now(),
      firstDate: widget.patrolRoute.startTime,
      lastDate: widget.patrolRoute.endTime ??
          DateTime.now(), // Fallback to current date/time if endTime is null
    );

    if (pickedDate != null && pickedDate != _selectedDate) {
      setState(() {
        _selectedDate = pickedDate;
      });
    }
  }

  void _resetFilter() {
    setState(() {
      _selectedDate = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    Duration patrolDuration = (widget.patrolRoute.endTime ?? DateTime.now())
        .difference(widget.patrolRoute.startTime);

    List<Incident> filteredIncidents = _incidents;

    // Apply date filter
    if (_selectedDate != null) {
      filteredIncidents = filteredIncidents
          .where((incident) =>
              incident.timestamp.toLocal().day == _selectedDate!.day &&
              incident.timestamp.toLocal().month == _selectedDate!.month &&
              incident.timestamp.toLocal().year == _selectedDate!.year)
          .toList();
    }

    // Apply incident type filter
    if (_selectedIncidentType != null && _selectedIncidentType != 'All Types') {
      filteredIncidents = filteredIncidents
          .where((incident) => incident.type == _selectedIncidentType)
          .toList();
    }

    // Apply search filter
    if (_searchQuery.isNotEmpty) {
      filteredIncidents = filteredIncidents
          .where((incident) => (incident.description).contains(_searchQuery))
          .toList();
    }

    // Apply sorting logic
    if (_selectedSortOrder == 'Date (Newest First)') {
      filteredIncidents.sort((a, b) => b.timestamp.compareTo(a.timestamp));
    } else if (_selectedSortOrder == 'Date (Oldest First)') {
      filteredIncidents.sort((a, b) => a.timestamp.compareTo(b.timestamp));
    }

    return Scaffold(
      appBar: AppBar(
        title: Text('Route Details'),
        backgroundColor: Colors.blueGrey,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text(
                'Details',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),
              _buildInfoTile('Start Time',
                  widget.patrolRoute.startTime.toLocal().toString()),
              _buildInfoTile(
                  'End Time', widget.patrolRoute.endTime!.toLocal().toString()),
              _buildInfoTile('Duration', '${patrolDuration.inMinutes} mins'),
              SizedBox(height: 20),
              SizedBox(
                height: 250,
                child: fm.FlutterMap(
                  options: fm.MapOptions(
                    initialCenter: ll.LatLng(
                        widget.patrolRoute.locations.first.latitude,
                        widget.patrolRoute.locations.first.longitude),
                    initialZoom: 15,
                  ),
                  children: [
                    fm.TileLayer(
                      urlTemplate:
                          'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                      userAgentPackageName: 'com.example.police_patrol_app',
                    ),
                    fm.PolylineLayer(polylines: _polylines.toList()),
                    fm.MarkerLayer(markers: _markers.toList()),
                  ],
                ),
              ),
              SizedBox(height: 20),
              Text(
                'Incidents',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              SizedBox(height: 10),

              // Incident reports listing goes here

              // Dropdown for incident types
              DropdownButton<String>(
                value: _selectedIncidentType ?? 'All Types',
                onChanged: (newValue) {
                  setState(() {
                    _selectedIncidentType = newValue;
                  });
                },
                items: _incidentTypes
                    .map<DropdownMenuItem<String>>((String value) {
                  return DropdownMenuItem<String>(
                    value: value,
                    child: Text(value),
                  );
                }).toList(),
              ),

              // Listing filtered incidents
              ListView.builder(
                shrinkWrap: true,
                itemCount: filteredIncidents.length,
                itemBuilder: (context, index) {
                  Incident incident = filteredIncidents[index];
                  return Card(
                    margin: EdgeInsets.symmetric(vertical: 5),
                    elevation: 5,
                    child: ListTile(
                      contentPadding: EdgeInsets.all(10),
                      leading: CircleAvatar(
                        backgroundColor: Colors.blueGrey[100],
                        child: (incident.mediaType == 'image' &&
                                incident.mediaUrl != null)
                            ? ClipOval(
                                child: Image.network(
                                  incident.mediaUrl ?? 'default_image_url',
                                  width: 48,
                                  height: 48,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : Icon(Icons.warning,
                                color: Colors.red,
                                size:
                                    28), // Fallback to warning icon if not an image
                      ),
                      title: Text(
                        incident.description,
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      subtitle: Text(
                        incident.timestamp.toLocal().toString(),
                        style: TextStyle(fontSize: 12),
                      ),
                      trailing: incident.mediaUrl != null
                          ? GestureDetector(
                              onTap: () => _viewMedia(incident.mediaUrl!,
                                  incident.mediaType ?? 'defaultType'),
                              child: Icon(
                                Icons.play_circle_fill,
                                color: Colors.blueGrey,
                                size: 30,
                              ),
                            )
                          : null,
                      onTap: () => _zoomToIncident(incident),
                    ),
                  );
                },
              )
            ],
          ),
        ),
      ),
    );
  }

  ListTile _buildInfoTile(String title, String value) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      title: Text(
        title,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
        ),
      ),
      subtitle: Text(
        value,
        style: TextStyle(fontSize: 15),
      ),
    );
  }
}

class FullScreenMediaView extends StatefulWidget {
  final String mediaUrl;
  final String mediaType;

  FullScreenMediaView({required this.mediaUrl, required this.mediaType});

  @override
  _FullScreenMediaViewState createState() => _FullScreenMediaViewState();
}

class _FullScreenMediaViewState extends State<FullScreenMediaView> {
  VideoPlayerController? _controller;

  @override
  void initState() {
    super.initState();
    if (widget.mediaType == 'video') {
      _controller = VideoPlayerController.network(widget.mediaUrl)
        ..initialize().then((_) {
          setState(() {});
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Media View'),
      ),
      body: Center(
        child: widget.mediaType == 'image'
            ? Image.network(widget.mediaUrl, fit: BoxFit.cover)
            : Container(
                // child: VideoPlayer(_controller!),

                child: Text('Video Player Placeholder'),
              ),
      ),
    );
  }

  @override
  void dispose() {
    // _controller?.dispose();
    super.dispose();
  }
}
