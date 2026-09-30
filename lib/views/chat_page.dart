import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:police_patrol_app/services/auth_service.dart';
import 'package:url_launcher/url_launcher.dart';

class ChatPage extends StatelessWidget {
  const ChatPage({super.key});

  static const _exampleContact = _ContactCenter(
    name: 'Ketua RT',
    phone: '08128068812',
    role: 'Kontak lingkungan',
    isExample: true,
  );

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
            tooltip: 'Keluar',
            icon: const Icon(Icons.logout_outlined),
            onPressed: () async {
              await AuthService().signOut();
              if (context.mounted) Navigator.popAndPushNamed(context, '/login');
            },
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot<Map<String, dynamic>>>(
        stream: FirebaseFirestore.instance
            .collection('contactCenters')
            .where('isActive', isEqualTo: true)
            .snapshots(),
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const _ContactBody(
                contacts: [], error: 'Daftar kontak tidak dapat dimuat.');
          }
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          final contacts = snapshot.data!.docs
              .map((doc) => _ContactCenter.fromJson(doc.data()))
              .whereType<_ContactCenter>()
              .toList();
          return _ContactBody(contacts: contacts, error: null);
        },
      ),
    );
  }
}

class _ContactBody extends StatelessWidget {
  const _ContactBody({required this.contacts, required this.error});
  final List<_ContactCenter> contacts;
  final String? error;

  @override
  Widget build(BuildContext context) {
    final showingExample = contacts.isEmpty;
    final items = showingExample ? [ChatPage._exampleContact] : contacts;
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 4, 16, 28),
      children: [
        Container(
          padding: const EdgeInsets.all(18),
          decoration: BoxDecoration(
              color: Colors.blueGrey.shade800,
              borderRadius: BorderRadius.circular(12)),
          child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(children: [
                  Icon(Icons.support_agent_outlined, color: Colors.white),
                  SizedBox(width: 10),
                  Text('Butuh bantuan?',
                      style: TextStyle(
                          color: Colors.white,
                          fontSize: 18,
                          fontWeight: FontWeight.w700))
                ]),
                SizedBox(height: 8),
                Text(
                    'Hubungi kontak lingkungan atau petugas terkait melalui telepon maupun WhatsApp.',
                    style: TextStyle(color: Color(0xFFDCE5E8))),
              ]),
        ),
        const SizedBox(height: 20),
        Text('Kontak tersedia',
            style: Theme.of(context)
                .textTheme
                .titleLarge
                ?.copyWith(fontWeight: FontWeight.w700)),
        const SizedBox(height: 6),
        const Text('Daftar ini diperbarui langsung dari Firebase.',
            style: TextStyle(color: Colors.blueGrey)),
        if (error != null) ...[
          const SizedBox(height: 12),
          _Notice(message: error!),
        ],
        if (showingExample) ...[
          const SizedBox(height: 12),
          const _Notice(
              message:
                  'Belum ada kontak aktif dari Firebase. Menampilkan data contoh.'),
        ],
        const SizedBox(height: 10),
        ...items.map((contact) => _ContactCard(contact: contact)),
      ],
    );
  }
}

class _ContactCard extends StatelessWidget {
  const _ContactCard({required this.contact});
  final _ContactCenter contact;

  @override
  Widget build(BuildContext context) => Card(
        margin: const EdgeInsets.only(bottom: 10),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child:
              Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              CircleAvatar(
                  backgroundColor: Colors.blueGrey.shade100,
                  child: Icon(Icons.person_outline,
                      color: Colors.blueGrey.shade800)),
              const SizedBox(width: 12),
              Expanded(
                  child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text(contact.name,
                        style: const TextStyle(
                            fontWeight: FontWeight.w700, fontSize: 16)),
                    if (contact.role.isNotEmpty)
                      Text(contact.role,
                          style: const TextStyle(color: Colors.blueGrey))
                  ])),
            ]),
            const SizedBox(height: 14),
            Row(children: [
              const Icon(Icons.phone_outlined,
                  size: 18, color: Colors.blueGrey),
              const SizedBox(width: 8),
              Text(contact.phone)
            ]),
            const SizedBox(height: 14),
            Row(children: [
              Expanded(
                  child: OutlinedButton.icon(
                      onPressed: () => _open(
                          context, Uri(scheme: 'tel', path: contact.phone)),
                      icon: const Icon(Icons.call_outlined),
                      label: const Text('Telepon'))),
              const SizedBox(width: 10),
              Expanded(
                  child: FilledButton.icon(
                      style: FilledButton.styleFrom(
                          backgroundColor: const Color(0xFF128C7E)),
                      onPressed: () => _open(
                          context,
                          Uri.parse(
                              'https://wa.me/${_whatsAppNumber(contact.phone)}')),
                      icon: const Icon(Icons.chat_outlined),
                      label: const Text('WhatsApp'))),
            ]),
          ]),
        ),
      );

  static String _whatsAppNumber(String number) {
    final digits = number.replaceAll(RegExp(r'\D'), '');
    return digits.startsWith('0') ? '62${digits.substring(1)}' : digits;
  }

  Future<void> _open(BuildContext context, Uri uri) async {
    if (await canLaunchUrl(uri) &&
        await launchUrl(uri, mode: LaunchMode.externalApplication)) {
      return;
    }
    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text(
              'Aplikasi Telepon atau WhatsApp tidak tersedia di perangkat ini.')));
    }
  }
}

class _ContactCenter {
  const _ContactCenter(
      {required this.name,
      required this.phone,
      required this.role,
      this.isExample = false});
  final String name;
  final String phone;
  final String role;
  final bool isExample;
  static _ContactCenter? fromJson(Map<String, dynamic> json) {
    final name = json['name'] as String?;
    final phone = json['phone'] as String?;
    if (name == null ||
        name.trim().isEmpty ||
        phone == null ||
        phone.trim().isEmpty) {
      return null;
    }
    return _ContactCenter(
        name: name.trim(),
        phone: phone.trim(),
        role: (json['role'] as String? ?? '').trim());
  }
}

class _Notice extends StatelessWidget {
  const _Notice({required this.message});
  final String message;
  @override
  Widget build(BuildContext context) => Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: Colors.amber.shade50, borderRadius: BorderRadius.circular(8)),
      child: Row(children: [
        Icon(Icons.info_outline, color: Colors.amber.shade900),
        const SizedBox(width: 8),
        Expanded(
            child:
                Text(message, style: TextStyle(color: Colors.amber.shade900)))
      ]));
}
