import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:police_patrol_app/services/auth_service.dart';

class CommandCenterPage extends StatefulWidget {
  @override
  _CommandCenterPageState createState() => _CommandCenterPageState();
}

class _CommandCenterPageState extends State<CommandCenterPage> {
  final AuthService _authService = AuthService();

  final List<Map<String, dynamic>> menuItems = [
    {
      'title': 'Incident Dashboard',
      'icon': Icons.dashboard_outlined,
      'color': Colors.blue,
      'route': '/incidentDashboard',
      'enabled': true,
    },
    {
      'title': 'Officer Monitoring',
      'icon': Icons.security_outlined,
      'color': Colors.green,
      'route': '/officerMonitoring',
      'enabled': true,
    },
    {
      'title': 'Resource Mgmt',
      'icon': Icons.manage_accounts_outlined,
      'color': Colors.orange,
      'route': '/resourceManagement',
      'enabled': true,
    },
    {
      'title': 'Incident Mgmt',
      'icon': Icons.warning_amber_rounded,
      'color': Colors.red,
      'route': '/incidentManagement',
      'enabled': true,
    },
    {
      'title': 'Data Analytics',
      'icon': Icons.bar_chart_outlined,
      'color': Colors.purple,
      'route': '/dataAnalytics',
      'enabled': true,
    },
    {
      'title': 'Historical Data',
      'icon': Icons.history_outlined,
      'color': Colors.teal,
      'route': null,
      'enabled': false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Command Center'),
        elevation: 0,
        actions: [
          IconButton(
            icon: Icon(Icons.logout),
            tooltip: 'Logout',
            onPressed: () async {
              await _authService.signOut();
              Get.offAllNamed('/login');
            },
          ),
        ],
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Selamat Datang, Komandan',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
              ),
              SizedBox(height: 8),
              Text(
                'Pilih menu operasional di bawah ini.',
                style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
              ),
              SizedBox(height: 24),
              Expanded(
                child: GridView.builder(
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    crossAxisSpacing: 16,
                    mainAxisSpacing: 16,
                    childAspectRatio: 0.9, // Memberi ruang vertikal lebih banyak
                  ),
                  itemCount: menuItems.length,
                  itemBuilder: (context, index) {
                    final item = menuItems[index];
                    return _buildMenuCard(
                      title: item['title'],
                      icon: item['icon'],
                      color: item['color'],
                      onTap: item['enabled']
                          ? () {
                              if (item['route'] != null) {
                                Get.toNamed(item['route']);
                              }
                            }
                          : null,
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMenuCard({
    required String title,
    required IconData icon,
    required Color color,
    required VoidCallback? onTap,
  }) {
    final bool isEnabled = onTap != null;
    return Card(
      elevation: isEnabled ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: isEnabled ? Colors.transparent : Colors.grey.shade300,
        ),
      ),
      color: isEnabled ? Colors.white : Colors.grey.shade50,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: isEnabled
                      ? color.withOpacity(0.1)
                      : Colors.grey.shade200,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  icon,
                  size: 32,
                  color: isEnabled ? color : Colors.grey.shade400,
                ),
              ),
              SizedBox(height: 12),
              Text(
                title,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: isEnabled ? Colors.black87 : Colors.grey.shade500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
