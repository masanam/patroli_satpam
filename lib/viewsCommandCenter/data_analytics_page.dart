import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:police_patrol_app/models/incident.dart';

class DataAnalyticsPage extends StatefulWidget {
  const DataAnalyticsPage({Key? key}) : super(key: key);

  @override
  _DataAnalyticsPageState createState() => _DataAnalyticsPageState();
}

class _DataAnalyticsPageState extends State<DataAnalyticsPage> {
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  int _touchedIndex = -1;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade100,
      appBar: AppBar(
        title: const Text('Data Analytics', style: TextStyle(fontWeight: FontWeight.bold)),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: _db.collection('incidents').snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data!.docs;
          if (docs.isEmpty) {
            return const Center(child: Text('Tidak ada data insiden untuk dianalisis.'));
          }

          // Hitung data untuk chart
          int pending = 0;
          int inProgress = 0;
          int resolved = 0;

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final statusIndex = data['status'] as int?;
            if (statusIndex == IncidentStatus.Pending.index) pending++;
            else if (statusIndex == IncidentStatus.InProgress.index) inProgress++;
            else if (statusIndex == IncidentStatus.Resolved.index) resolved++;
          }

          final total = pending + inProgress + resolved;

          return SingleChildScrollView(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  _buildSummaryCards(total, pending, inProgress, resolved),
                  const SizedBox(height: 24),
                  Card(
                    elevation: 2,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: [
                          const Text(
                            'Distribusi Status Insiden',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          const SizedBox(height: 32),
                          SizedBox(
                            height: 260, // Diperbesar dari 220 untuk menghindari overflow
                            child: PieChart(
                              PieChartData(
                                pieTouchData: PieTouchData(
                                  touchCallback: (FlTouchEvent event, pieTouchResponse) {
                                    setState(() {
                                      if (!event.isInterestedForInteractions ||
                                          pieTouchResponse == null ||
                                          pieTouchResponse.touchedSection == null) {
                                        _touchedIndex = -1;
                                        return;
                                      }
                                      _touchedIndex =
                                          pieTouchResponse.touchedSection!.touchedSectionIndex;
                                    });
                                  },
                                ),
                                borderData: FlBorderData(show: false),
                                sectionsSpace: 4,
                                centerSpaceRadius: 50,
                                sections: [
                                  _buildPieChartSectionData(
                                    value: pending.toDouble(),
                                    title: '$pending',
                                    color: Colors.red,
                                    index: 0,
                                  ),
                                  _buildPieChartSectionData(
                                    value: inProgress.toDouble(),
                                    title: '$inProgress',
                                    color: Colors.orange,
                                    index: 1,
                                  ),
                                  _buildPieChartSectionData(
                                    value: resolved.toDouble(),
                                    title: '$resolved',
                                    color: Colors.green,
                                    index: 2,
                                  ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(height: 32),
                          Wrap(
                            alignment: WrapAlignment.center,
                            spacing: 16,
                            runSpacing: 12,
                            children: [
                              _buildLegend(color: Colors.red, text: 'Pending'),
                              _buildLegend(color: Colors.orange, text: 'In Progress'),
                              _buildLegend(color: Colors.green, text: 'Resolved'),
                            ],
                          )
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCards(int total, int pending, int inProgress, int resolved) {
    return GridView.count(
      crossAxisCount: 2,
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.5,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      children: [
        _buildStatCard('Total Insiden', total.toString(), Colors.blue),
        _buildStatCard('Pending', pending.toString(), Colors.red),
        _buildStatCard('In Progress', inProgress.toString(), Colors.orange),
        _buildStatCard('Resolved', resolved.toString(), Colors.green),
      ],
    );
  }

  Widget _buildStatCard(String title, String value, Color color) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey.shade600,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              value,
              style: TextStyle(
                fontSize: 28,
                color: color,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  PieChartSectionData _buildPieChartSectionData({
    required double value,
    required String title,
    required Color color,
    required int index,
  }) {
    final isTouched = index == _touchedIndex;
    final fontSize = isTouched ? 20.0 : 16.0;
    final radius = isTouched ? 60.0 : 50.0;

    return PieChartSectionData(
      color: color,
      value: value > 0 ? value : 0.001, // Hindari error FlChart jika value 0
      title: value > 0 ? title : '',
      radius: radius,
      titleStyle: TextStyle(
        fontSize: fontSize,
        fontWeight: FontWeight.bold,
        color: Colors.white,
      ),
    );
  }

  Widget _buildLegend({required Color color, required String text}) {
    return Row(
      children: [
        Container(
          width: 16,
          height: 16,
          decoration: BoxDecoration(shape: BoxShape.circle, color: color),
        ),
        const SizedBox(width: 8),
        Text(
          text,
          style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.black87),
        )
      ],
    );
  }
}
