import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:police_patrol_app/models/contact_center.dart';
import 'package:police_patrol_app/services/auth_service.dart';
import 'package:police_patrol_app/services/firebase_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F4),
      appBar: AppBar(
        title: const Text('Contact Center'),
        backgroundColor: Colors.transparent,
        foregroundColor: Colors.blueGrey.shade900,
        elevation: 0,
        actions: [
          IconButton(
            tooltip: 'Seed Data',
            icon: const Icon(Icons.cloud_upload_outlined),
            onPressed: () async {
              try {
                final firestore = FirebaseFirestore.instance;
                final batch = firestore.batch();
                final dummyData = {
                  "CC-001": {
                    "name": "Komandan Regu Patroli",
                    "whatsappNumber": "6281234567890",
                    "phoneNumber": "021-5551001",
                    "position": "Komandan Regu",
                    "unit": "Unit Patroli Alpha",
                    "category": 1,
                    "isActive": true,
                    "description": "Komandan utama regu patroli. Hubungi untuk koordinasi jadwal dan penugasan."
                  },
                  "CC-002": {
                    "name": "Pusat Komando (Posko)",
                    "whatsappNumber": "6281298765432",
                    "phoneNumber": "021-5551002",
                    "position": "Operator Posko",
                    "unit": "Pusat Komando",
                    "category": 1,
                    "isActive": true,
                    "description": "Pusat koordinasi operasional 24 jam. Laporkan situasi lapangan ke sini."
                  },
                  "CC-003": {
                    "name": "Hotline Darurat Polisi",
                    "whatsappNumber": "621110",
                    "phoneNumber": "110",
                    "position": "Layanan Darurat",
                    "unit": "Kepolisian RI",
                    "category": 0,
                    "isActive": true,
                    "description": "Layanan darurat kepolisian 24 jam. Hubungi segera dalam kondisi darurat."
                  },
                  "CC-004": {
                    "name": "Unit Gawat Darurat (UGD)",
                    "whatsappNumber": "621119",
                    "phoneNumber": "119",
                    "position": "Ambulans & Medis",
                    "unit": "Dinas Kesehatan",
                    "category": 0,
                    "isActive": true,
                    "description": "Layanan ambulans dan pertolongan pertama medis."
                  },
                  "CC-005": {
                    "name": "Pemadam Kebakaran",
                    "whatsappNumber": "621113",
                    "phoneNumber": "113",
                    "position": "Damkar",
                    "unit": "Dinas Pemadam Kebakaran",
                    "category": 0,
                    "isActive": true,
                    "description": "Layanan pemadam kebakaran dan penyelamatan."
                  },
                };

                for (final entry in dummyData.entries) {
                  final ref = firestore.collection('contactCenters').doc(entry.key);
                  batch.set(ref, {
                    ...entry.value,
                    'id': entry.key,
                  });
                }
                await batch.commit();
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Data berhasil di-seed!')));
                }
              } catch (e) {
                if (context.mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(content: Text('Gagal seed: $e')));
                }
              }
            },
          ),
          IconButton(
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout_outlined),
            onPressed: () async {
              await AuthService().signOut();
              if (context.mounted) Navigator.popAndPushNamed(context, '/login');
            },
          ),
        ],
      ),
      body: StreamBuilder<List<ContactCenter>>(
        stream: FirebaseService().streamContactCenters(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return _ContactBody(
              contacts: const [],
              error: 'Gagal memuat daftar kontak: ${snapshot.error}',
            );
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final contacts = snapshot.data ?? [];
          return _ContactBody(contacts: contacts, error: null);
        },
      ),
    );
  }
}

class _ContactBody extends StatelessWidget {
  const _ContactBody({required this.contacts, required this.error});
  final List<ContactCenter> contacts;
  final String? error;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      children: [
        // Header Banner
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
            color: Colors.blueGrey.shade800,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(children: [
                Icon(Icons.support_agent_outlined, color: Colors.white),
                SizedBox(width: 10),
                Text(
                  'Butuh bantuan?',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ]),
              SizedBox(height: 8),
              Text(
                'Hubungi petugas atau layanan darurat melalui telepon maupun WhatsApp.',
                style: TextStyle(color: Color(0xFFDCE5E8)),
              ),
            ],
          ),
        ),
        const SizedBox(height: 20),
        Text(
          'Kontak Tersedia',
          style: Theme.of(context)
              .textTheme
              .titleLarge
              ?.copyWith(fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 6),
        const Text(
          'Data diambil langsung dari Firebase secara realtime.',
          style: TextStyle(color: Colors.blueGrey),
        ),
        if (error != null) ...[
          const SizedBox(height: 12),
          _Notice(message: error!),
        ],
        const SizedBox(height: 12),
        if (contacts.isEmpty)
          const _EmptyState()
        else
          ...contacts.map((c) => _ContactCard(contact: c)),
      ],
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.contact});
  final ContactCenter contact;

  Color _categoryColor(ContactCategory cat) {
    switch (cat) {
      case ContactCategory.emergency:
        return Colors.red.shade700;
      case ContactCategory.patrol:
        return Colors.blue.shade700;
      case ContactCategory.report:
        return Colors.orange.shade700;
      case ContactCategory.administrative:
        return Colors.teal.shade700;
    }
  }

  IconData _categoryIcon(ContactCategory cat) {
    switch (cat) {
      case ContactCategory.emergency:
        return Icons.emergency_outlined;
      case ContactCategory.patrol:
        return Icons.local_police_outlined;
      case ContactCategory.report:
        return Icons.report_outlined;
      case ContactCategory.administrative:
        return Icons.admin_panel_settings_outlined;
    }
  }

  String _categoryLabel(ContactCategory cat) {
    switch (cat) {
      case ContactCategory.emergency:
        return 'Darurat';
      case ContactCategory.patrol:
        return 'Patroli';
      case ContactCategory.report:
        return 'Pelaporan';
      case ContactCategory.administrative:
        return 'Administrasi';
    }
  }

  @override
  Widget build(BuildContext context) {
    final catColor = _categoryColor(contact.category);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: catColor.withOpacity(0.1),
                  child: Icon(
                    _categoryIcon(contact.category),
                    color: catColor,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        contact.name,
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 16,
                        ),
                      ),
                      if (contact.position != null &&
                          contact.position!.isNotEmpty)
                        Text(
                          contact.position!,
                          style: const TextStyle(color: Colors.blueGrey),
                        ),
                      if (contact.unit != null && contact.unit!.isNotEmpty)
                        Text(
                          contact.unit!,
                          style: TextStyle(
                              color: Colors.blueGrey.shade400, fontSize: 12),
                        ),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: catColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _categoryLabel(contact.category),
                    style: TextStyle(
                      color: catColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            // Nomor WhatsApp
            Row(
              children: [
                const Icon(Icons.chat_outlined, size: 16, color: Colors.blueGrey),
                const SizedBox(width: 8),
                Text(
                  '+${contact.whatsappNumber}',
                  style: const TextStyle(fontWeight: FontWeight.w500),
                ),
              ],
            ),
            // Nomor Telepon (jika ada & berbeda dengan WA)
            if (contact.phoneNumber != null &&
                contact.phoneNumber!.isNotEmpty) ...[
              const SizedBox(height: 4),
              Row(
                children: [
                  const Icon(Icons.phone_outlined, size: 16, color: Colors.blueGrey),
                  const SizedBox(width: 8),
                  Text(
                    contact.phoneNumber!,
                    style: const TextStyle(fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            ],
            if (contact.description != null &&
                contact.description!.isNotEmpty) ...[
              const SizedBox(height: 8),
              Text(
                contact.description!,
                style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
              ),
            ],
            const SizedBox(height: 14),
            // Tombol aksi
            Row(
              children: [
                if (contact.phoneNumber != null &&
                    contact.phoneNumber!.isNotEmpty)
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: () => _open(
                        context,
                        Uri(scheme: 'tel', path: contact.phoneNumber),
                      ),
                      icon: const Icon(Icons.call_outlined),
                      label: const Text('Telepon'),
                    ),
                  ),
                if (contact.phoneNumber != null &&
                    contact.phoneNumber!.isNotEmpty)
                  const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: const Color(0xFF128C7E),
                    ),
                    onPressed: () => _open(
                      context,
                      Uri.parse(contact.whatsappUrl),
                    ),
                    icon: const Icon(Icons.chat_outlined),
                    label: const Text('WhatsApp'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _open(BuildContext context, Uri uri) async {
    if (await canLaunchUrl(uri) &&
        await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      return;
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
        content: Text(
            'Aplikasi Telepon atau WhatsApp tidak tersedia di perangkat ini.'),
      ));
    }
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) => const Padding(
        padding: EdgeInsets.symmetric(vertical: 48),
        child: Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(Icons.contact_phone_outlined, size: 48, color: Colors.blueGrey),
              SizedBox(height: 12),
              Text(
                'Belum ada kontak aktif.',
                style: TextStyle(color: Colors.blueGrey, fontSize: 15),
              ),
              SizedBox(height: 4),
              Text(
                'Data akan muncul setelah admin menambahkan\nkontak di Firebase.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.blueGrey, fontSize: 13),
              ),
            ],
          ),
        ),
      );
}

class _Notice extends StatelessWidget {
  const _Notice({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          borderRadius: BorderRadius.circular(8),
        ),
        child: Row(children: [
          Icon(Icons.info_outline, color: Colors.amber.shade900),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              message,
              style: TextStyle(color: Colors.amber.shade900),
            ),
          ),
        ]),
      );
}
