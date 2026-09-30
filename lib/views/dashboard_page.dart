import 'package:flutter/material.dart';
import 'package:police_patrol_app/services/auth_service.dart';

class DashboardPage extends StatefulWidget {
  @override
  _DashboardPageState createState() => _DashboardPageState();
}

class _DashboardPageState extends State<DashboardPage> {
  final AuthService _authService = AuthService();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Patrol dashboard'),
        actions: [
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await _authService.signOut();
              if (!context.mounted) return;
              Navigator.popAndPushNamed(context, '/login');
            },
          )
        ],
      ),
      body: SingleChildScrollView(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'OPERASI PATROLI',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: Colors.blueGrey,
                          fontWeight: FontWeight.w700,
                        ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Selamat bertugas',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Pilih aktivitas yang ingin Anda lanjutkan.',
                    style: TextStyle(color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 24),
                  _buildDashboardCard(
                    title: 'Peta patroli',
                    subtitle: 'Lihat rute dan checkpoint',
                    imageAsset: 'images/map.png',
                    onTap: () => Navigator.pushNamed(context, '/map'),
                  ),
                  _buildDashboardCard(
                    title: 'Contact Center',
                    subtitle: 'Telepon atau WhatsApp kontak penting',
                    imageAsset: 'images/chat.png',
                    onTap: () => Navigator.pushNamed(context, '/chat'),
                  ),
                  _buildDashboardCard(
                    title: 'Laporan patroli',
                    subtitle: 'Lihat rute, insiden, dan scan checkpoint',
                    imageAsset: 'images/report.png',
                    onTap: () => Navigator.pushNamed(context, '/reportView'),
                  ),
                  const SizedBox(height: 8),
                  OutlinedButton.icon(
                    onPressed: () => Navigator.pushNamed(context, '/report'),
                    icon: const Icon(Icons.add_alert_outlined),
                    label: const Text('Buat laporan insiden'),
                    style: OutlinedButton.styleFrom(
                      minimumSize: const Size.fromHeight(48),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDashboardCard({
    required String title,
    required String subtitle,
    required String imageAsset,
    required VoidCallback onTap,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Row(
          children: [
            SizedBox(
              width: 96,
              height: 88,
              child: Image.asset(
                imageAsset,
                fit: BoxFit.cover,
              ),
            ),
            Expanded(
              child: Padding(
                padding:
                    const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: const TextStyle(fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: const TextStyle(color: Colors.blueGrey),
                    ),
                  ],
                ),
              ),
            ),
            const Padding(
              padding: EdgeInsets.only(right: 16),
              child: Icon(Icons.chevron_right, color: Colors.blueGrey),
            ),
          ],
        ),
      ),
    );
  }
}
