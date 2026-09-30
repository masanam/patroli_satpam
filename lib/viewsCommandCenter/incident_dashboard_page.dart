import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:police_patrol_app/models/incident.dart';
import 'package:police_patrol_app/viewsCommandCenter/incident_details_page.dart';

class IncidentDashboardPage extends StatefulWidget {
  @override
  _IncidentDashboardPageState createState() => _IncidentDashboardPageState();
}

class _IncidentDashboardPageState extends State<IncidentDashboardPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;
  IncidentStatus? selectedStatus = null;
  List<String> statusOptions = ["All"] +
      IncidentStatus.values.map((e) => e.toString().split('.').last).toList();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Incident Dashboard'),
        elevation: 0,
      ),
      body: Column(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            color: Theme.of(context).appBarTheme.backgroundColor,
            child: Row(
              children: [
                Text(
                  "Filter Status: ",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                SizedBox(width: 12),
                Expanded(
                  child: Container(
                    padding: EdgeInsets.symmetric(horizontal: 12),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButton<String>(
                        isExpanded: true,
                        value: selectedStatus?.toString().split('.').last ?? "All",
                        items: statusOptions.map((String value) {
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(value),
                          );
                        }).toList(),
                        onChanged: (newValue) {
                          setState(() {
                            if (newValue == "All") {
                              selectedStatus = null;
                            } else {
                              selectedStatus = IncidentStatus.values.firstWhere(
                                  (e) => e.toString().split('.').last == newValue);
                            }
                          });
                        },
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
          Expanded(
            child: StreamBuilder(
              // Query tetap mengambil semua, lalu filter dilakukan di memori (Dart). 
              // Ini menghindari error 'The query requires an index' ketika filter & order digabung tanpa composite index.
              stream: _db
                  .collection('incidents')
                  .orderBy('timestamp', descending: true)
                  .snapshots(),
              builder: (BuildContext context, AsyncSnapshot<QuerySnapshot> snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Error: ${snapshot.error}'));
                }
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return Center(child: CircularProgressIndicator());
                }

                // Filter secara lokal berdasarkan selectedStatus
                var docs = snapshot.data!.docs;
                if (selectedStatus != null) {
                  docs = docs.where((doc) {
                    final data = doc.data() as Map<String, dynamic>;
                    return data['status'] == selectedStatus!.index;
                  }).toList();
                }

                if (docs.isEmpty) {
                  return Center(
                    child: Text('Tidak ada insiden.',
                        style: TextStyle(fontSize: 16, color: Colors.grey)),
                  );
                }

                return ListView.builder(
                  padding: EdgeInsets.all(12),
                  itemCount: docs.length,
                  itemBuilder: (context, index) {
                    try {
                      Incident incident =
                          Incident.fromJson(docs[index].data() as Map<String, dynamic>);
                      return Card(
                        margin: EdgeInsets.only(bottom: 12),
                        elevation: 2,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(12),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) =>
                                    IncidentDetailsPage(incident: incident),
                              ),
                            );
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(16.0),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                CircleAvatar(
                                  radius: 24,
                                  backgroundColor:
                                      getColorBasedOnStatus(incident.status).withOpacity(0.15),
                                  child: getIconBasedOnStatus(incident.status),
                                ),
                                SizedBox(width: 16),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Row(
                                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                        children: [
                                          Expanded(
                                            child: Text(
                                              incident.type ?? 'Insiden',
                                              style: TextStyle(
                                                  fontWeight: FontWeight.bold, fontSize: 16),
                                              maxLines: 1,
                                              overflow: TextOverflow.ellipsis,
                                            ),
                                          ),
                                          SizedBox(width: 8),
                                          Container(
                                            padding: EdgeInsets.symmetric(
                                                horizontal: 8, vertical: 4),
                                            decoration: BoxDecoration(
                                              color: getColorBasedOnStatus(incident.status)
                                                  .withOpacity(0.1),
                                              borderRadius: BorderRadius.circular(12),
                                            ),
                                            child: Text(
                                              incident.status?.toString().split('.').last ??
                                                  'Unknown',
                                              style: TextStyle(
                                                color: getColorBasedOnStatus(incident.status),
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                          ),
                                        ],
                                      ),
                                      SizedBox(height: 8),
                                      Text(
                                        incident.description,
                                        maxLines: 2,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(color: Colors.grey.shade700),
                                      ),
                                      SizedBox(height: 8),
                                      Row(
                                        children: [
                                          Icon(Icons.access_time,
                                              size: 14, color: Colors.grey.shade500),
                                          SizedBox(width: 4),
                                          Text(
                                            "${incident.timestamp.day.toString().padLeft(2, '0')}/${incident.timestamp.month.toString().padLeft(2, '0')}/${incident.timestamp.year} ${incident.timestamp.hour.toString().padLeft(2, '0')}:${incident.timestamp.minute.toString().padLeft(2, '0')}",
                                            style: TextStyle(
                                                color: Colors.grey.shade500, fontSize: 12),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    } catch (e) {
                      print("Error while converting document to Incident: $e");
                      return SizedBox.shrink();
                    }
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Color getColorBasedOnStatus(IncidentStatus? status) {
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

  Icon getIconBasedOnStatus(IncidentStatus? status) {
    Color color = getColorBasedOnStatus(status);
    switch (status) {
      case IncidentStatus.Pending:
        return Icon(Icons.pending_actions, color: color);
      case IncidentStatus.Resolved:
        return Icon(Icons.check_circle, color: color);
      case IncidentStatus.InProgress:
        return Icon(Icons.sync, color: color);
      default:
        return Icon(Icons.info, color: color);
    }
  }
}
