import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:police_patrol_app/models/incident.dart';
import 'package:police_patrol_app/services/firebase_service.dart';
import 'package:police_patrol_app/services/location_service.dart';
import 'package:uuid/uuid.dart';
import 'dart:io';

class ReportPage extends StatefulWidget {
  final String? patrolRouteId; // The ID of the current patrol route

  const ReportPage({super.key, required this.patrolRouteId});

  @override
  State<ReportPage> createState() => _ReportPageState();
}

class _ReportPageState extends State<ReportPage> {
  final FirebaseService _firebaseService = FirebaseService();
  final LocationService _locationService = LocationService();
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  File? _selectedMedia;
  String? _mediaType;
  String _incidentStatus = 'Pending'; // Default status, can be modified
  bool _isSubmitting = false;

  Future<void> _pickMedia(
      BuildContext context, bool isCamera, bool isImage) async {
    final picker = ImagePicker();
    final XFile? media = isImage
        ? await picker.pickImage(
            source: isCamera ? ImageSource.camera : ImageSource.gallery)
        : await picker.pickVideo(
            source: isCamera ? ImageSource.camera : ImageSource.gallery);

    if (media != null) {
      setState(() {
        _selectedMedia = File(media.path);
        _mediaType = isImage ? 'image' : 'video';
      });
    }
  }

  Future<String> _uploadMedia(File media, String mediaType) async {
    try {
      final extension = mediaType == 'video' ? 'mp4' : 'jpg';
      final contentType = mediaType == 'video' ? 'video/mp4' : 'image/jpeg';
      final ref = FirebaseStorage.instance
          .ref()
          .child('incidents/${const Uuid().v4()}.$extension');
      final snapshot = await ref.putFile(
        media,
        SettableMetadata(contentType: contentType),
      );
      return await snapshot.ref.getDownloadURL();
    } on FirebaseException catch (error) {
      throw StateError(_storageErrorMessage(error));
    }
  }

  String _storageErrorMessage(FirebaseException error) {
    switch (error.code) {
      case 'unauthorized':
        return 'Anda tidak memiliki izin untuk mengunggah bukti. Periksa aturan Firebase Storage.';
      case 'canceled':
        return 'Unggah bukti dibatalkan.';
      case 'object-not-found':
        return 'Berkas bukti tidak ditemukan.';
      case 'quota-exceeded':
        return 'Kuota penyimpanan Firebase telah penuh.';
      default:
        return 'Unggah bukti gagal (${error.code}). Periksa koneksi lalu coba lagi.';
    }
  }

  final TextEditingController _descriptionController = TextEditingController();
  String _incidentType = 'Theft'; // Default type, can be modified
  String _errorMessage = '';

  Future<void> _addIncident(Incident incident) async {
    // Associate the incident with the provided patrolRouteId
    Incident newIncident = Incident(
      id: incident.id,
      latitude: incident.latitude,
      longitude: incident.longitude,
      description: incident.description,
      timestamp: incident.timestamp,
      reportedBy: incident.reportedBy,
      type: incident.type,
      mediaUrl: incident.mediaUrl,
      mediaType: incident.mediaType,
      patrolRouteId: widget.patrolRouteId,
      status: incident.status,
    );

    await _firebaseService.addIncident(newIncident);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F4),
      appBar: AppBar(title: const Text('Laporan insiden')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 720),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Text(
                    'Catat kejadian',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Lengkapi informasi dan lampirkan bukti bila tersedia.',
                    style: TextStyle(color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 20),
                  _sectionCard(
                    title: 'Klasifikasi',
                    icon: Icons.category_outlined,
                    child: Column(
                      children: [
                        DropdownButtonFormField<String>(
                          initialValue: _incidentType,
                          decoration: const InputDecoration(
                            labelText: 'Jenis insiden',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'Theft', child: Text('Pencurian')),
                            DropdownMenuItem(
                                value: 'Assault', child: Text('Kekerasan')),
                            DropdownMenuItem(
                                value: 'Accident', child: Text('Kecelakaan')),
                            DropdownMenuItem(
                                value: 'Other', child: Text('Lainnya')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _incidentType = value);
                            }
                          },
                        ),
                        const SizedBox(height: 14),
                        DropdownButtonFormField<String>(
                          initialValue: _incidentStatus,
                          decoration: const InputDecoration(
                            labelText: 'Status',
                            border: OutlineInputBorder(),
                          ),
                          items: const [
                            DropdownMenuItem(
                                value: 'Pending', child: Text('Menunggu')),
                            DropdownMenuItem(
                                value: 'InProgress', child: Text('Ditangani')),
                            DropdownMenuItem(
                                value: 'Resolved', child: Text('Selesai')),
                          ],
                          onChanged: (value) {
                            if (value != null) {
                              setState(() => _incidentStatus = value);
                            }
                          },
                        ),
                      ],
                    ),
                  ),
                  _sectionCard(
                    title: 'Deskripsi',
                    icon: Icons.notes_outlined,
                    child: TextFormField(
                      controller: _descriptionController,
                      minLines: 4,
                      maxLines: 7,
                      textCapitalization: TextCapitalization.sentences,
                      decoration: const InputDecoration(
                        hintText: 'Jelaskan kejadian, kondisi, dan tindakan…',
                        border: OutlineInputBorder(),
                        alignLabelWithHint: true,
                      ),
                      validator: (value) =>
                          value == null || value.trim().isEmpty
                              ? 'Deskripsi wajib diisi'
                              : null,
                    ),
                  ),
                  _sectionCard(
                    title: 'Bukti foto',
                    icon: Icons.photo_camera_outlined,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Wrap(
                          spacing: 10,
                          runSpacing: 8,
                          children: [
                            OutlinedButton.icon(
                              onPressed: () => _pickMedia(context, true, true),
                              icon: const Icon(Icons.camera_alt_outlined),
                              label: const Text('Ambil foto'),
                            ),
                            OutlinedButton.icon(
                              onPressed: () => _pickMedia(context, false, true),
                              icon: const Icon(Icons.photo_library_outlined),
                              label: const Text('Pilih dari galeri'),
                            ),
                          ],
                        ),
                        if (_selectedMedia != null) ...[
                          const SizedBox(height: 12),
                          ClipRRect(
                            borderRadius: BorderRadius.circular(6),
                            child: Image.file(
                              _selectedMedia!,
                              fit: BoxFit.cover,
                              height: 220,
                            ),
                          ),
                          Align(
                            alignment: Alignment.centerRight,
                            child: TextButton.icon(
                              onPressed: () => setState(() {
                                _selectedMedia = null;
                                _mediaType = null;
                              }),
                              icon: const Icon(Icons.delete_outline),
                              label: const Text('Hapus foto'),
                            ),
                          ),
                        ],
                      ],
                    ),
                  ),
                  _sectionCard(
                    title: 'Lokasi',
                    icon: Icons.location_on_outlined,
                    child: const Text(
                      'Lokasi perangkat akan dicatat saat laporan dikirim.',
                      style: TextStyle(color: Colors.blueGrey),
                    ),
                  ),
                  const SizedBox(height: 96),
                ],
              ),
            ),
          ),
        ),
      ),
      bottomNavigationBar: SafeArea(
        minimum: const EdgeInsets.fromLTRB(16, 8, 16, 12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            if (_errorMessage.isNotEmpty) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(_errorMessage,
                    style: TextStyle(color: Colors.red.shade800)),
              ),
            ],
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: _isSubmitting ? null : _submitReport,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2))
                    : const Icon(Icons.send_outlined),
                label:
                    Text(_isSubmitting ? 'Mengirim laporan…' : 'Kirim laporan'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _sectionCard({
    required String title,
    required IconData icon,
    required Widget child,
  }) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Row(
              children: [
                Icon(icon, color: Colors.blueGrey),
                const SizedBox(width: 8),
                Text(title,
                    style: const TextStyle(fontWeight: FontWeight.w700)),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }

  Future<void> _submitReport() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;
    setState(() {
      _isSubmitting = true;
      _errorMessage = '';
    });

    try {
      var location = await _locationService.getCurrentLocation();
      if (location != null) {
        String id = DateTime.now()
            .millisecondsSinceEpoch
            .toString(); // Generating a unique ID based on current time
        DateTime timestamp = DateTime.now(); // Current time as the timestamp

        String? mediaUrl;
        if (_selectedMedia != null && _mediaType != null) {
          mediaUrl = await _uploadMedia(_selectedMedia!, _mediaType!);
        }

        IncidentStatus statusEnum = IncidentStatus.values.firstWhere(
          (e) => e.toString() == 'IncidentStatus.$_incidentStatus',
          orElse: () => IncidentStatus.Pending,
        );

        Incident incident = Incident(
          id: id,
          type: _incidentType,
          description: _descriptionController.text,
          latitude: location.latitude!,
          longitude: location.longitude!,
          mediaUrl: mediaUrl,
          mediaType: _mediaType,
          timestamp: timestamp,
          patrolRouteId: widget.patrolRouteId, // Assign the patrolRouteId here
          status: statusEnum,
        );

        await _addIncident(incident);
        if (mounted) {
          Navigator.pop(context);
        }
      } else if (mounted) {
        setState(() {
          _errorMessage =
              "Couldn't fetch location. Please enable location services.";
        });
      }
    } catch (error) {
      if (mounted) {
        setState(() {
          _errorMessage = error is StateError
              ? error.message.toString()
              : 'Laporan tidak dapat dikirim. Periksa koneksi lalu coba lagi.';
        });
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
