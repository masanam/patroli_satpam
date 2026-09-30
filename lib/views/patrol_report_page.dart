import 'package:flutter/material.dart';
import 'package:police_patrol_app/models/patrol_report.dart';
import 'package:police_patrol_app/services/auth_service.dart';
import 'package:police_patrol_app/services/firebase_service.dart';
import 'package:uuid/uuid.dart';

class PatrolReportPage extends StatefulWidget {
  final Function onReportSubmitted;
  final String? patrolRouteId;

  const PatrolReportPage({
    super.key,
    required this.onReportSubmitted,
    this.patrolRouteId,
  });

  @override
  State<PatrolReportPage> createState() => _PatrolReportPageState();
}

class _PatrolReportPageState extends State<PatrolReportPage> {
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _warrantDateTimeController =
      TextEditingController();
  final TextEditingController _natureOfPatrolController =
      TextEditingController();

  int _numberOfPersonnel = 1; // For slider
  bool _isFootPatrol = false; // For switch
  String _typeOfPatrol = 'Patroli Wilayah';
  bool _isSubmitting = false;
  DateTime? _warrantDateTime;
  String? _errorMessage;

  @override
  void dispose() {
    _warrantDateTimeController.dispose();
    _natureOfPatrolController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F4),
      appBar: AppBar(title: const Text('Laporan patroli')),
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
                    'Rencana patroli',
                    style: Theme.of(context)
                        .textTheme
                        .headlineSmall
                        ?.copyWith(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Isi informasi surat perintah dan personel sebelum mulai.',
                    style: TextStyle(color: Colors.blueGrey),
                  ),
                  const SizedBox(height: 20),
                  Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Surat perintah',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _warrantDateTimeController,
                            readOnly: true,
                            decoration: const InputDecoration(
                              labelText: 'Tanggal dan waktu',
                              prefixIcon: Icon(Icons.calendar_month_outlined),
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) => value == null || value.isEmpty
                                ? 'Tanggal surat wajib dipilih'
                                : null,
                            onTap: _selectWarrantDateTime,
                          ),
                        ],
                      ),
                    ),
                  ),
                  Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const Text(
                            'Rincian patroli',
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 14),
                          DropdownButtonFormField<String>(
                            initialValue: _typeOfPatrol,
                            decoration: const InputDecoration(
                              labelText: 'Jenis patroli',
                              border: OutlineInputBorder(),
                            ),
                            items: const [
                              DropdownMenuItem(
                                  value: 'Patroli Wilayah',
                                  child: Text('Patroli wilayah')),
                              DropdownMenuItem(
                                  value: 'Patroli Terpadu',
                                  child: Text('Patroli terpadu')),
                              DropdownMenuItem(
                                  value: 'Patroli Rutin',
                                  child: Text('Patroli rutin')),
                            ],
                            onChanged: (value) {
                              if (value != null) {
                                setState(() => _typeOfPatrol = value);
                              }
                            },
                          ),
                          const SizedBox(height: 14),
                          TextFormField(
                            controller: _natureOfPatrolController,
                            textCapitalization: TextCapitalization.sentences,
                            decoration: const InputDecoration(
                              labelText: 'Sifat / tujuan patroli',
                              hintText: 'Contoh: pengamanan area pasar',
                              border: OutlineInputBorder(),
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                    ? 'Sifat patroli wajib diisi'
                                    : null,
                          ),
                          const SizedBox(height: 8),
                          SwitchListTile.adaptive(
                            contentPadding: EdgeInsets.zero,
                            title: const Text('Patroli jalan kaki'),
                            subtitle:
                                const Text('Matikan untuk patroli kendaraan'),
                            value: _isFootPatrol,
                            onChanged: (value) =>
                                setState(() => _isFootPatrol = value),
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              const Expanded(
                                child: Text(
                                  'Jumlah personel',
                                  style: TextStyle(fontWeight: FontWeight.w600),
                                ),
                              ),
                              Chip(label: Text('$_numberOfPersonnel orang')),
                            ],
                          ),
                          Slider(
                            value: _numberOfPersonnel.toDouble(),
                            min: 1,
                            max: 20,
                            divisions: 19,
                            label: '$_numberOfPersonnel',
                            onChanged: (value) => setState(
                              () => _numberOfPersonnel = value.round(),
                            ),
                          ),
                        ],
                      ),
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
            if (_errorMessage != null) ...[
              Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.red.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  _errorMessage!,
                  style: TextStyle(color: Colors.red.shade800),
                ),
              ),
            ],
            SizedBox(
              height: 50,
              child: FilledButton.icon(
                onPressed: _isSubmitting ? null : _submitPatrolReport,
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Icon(Icons.play_arrow),
                label: Text(
                    _isSubmitting ? 'Menyimpan…' : 'Simpan dan mulai patroli'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _selectWarrantDateTime() async {
    final now = DateTime.now();
    final pickedDate = await showDatePicker(
      context: context,
      initialDate: _warrantDateTime ?? now,
      firstDate: DateTime(2000),
      lastDate: DateTime(2100),
    );
    if (!mounted || pickedDate == null) return;

    final pickedTime = await showTimePicker(
      context: context,
      initialTime: _warrantDateTime == null
          ? TimeOfDay.now()
          : TimeOfDay.fromDateTime(_warrantDateTime!),
    );
    if (!mounted || pickedTime == null) return;

    final dateTime = DateTime(
      pickedDate.year,
      pickedDate.month,
      pickedDate.day,
      pickedTime.hour,
      pickedTime.minute,
    );
    final dateLabel =
        MaterialLocalizations.of(context).formatMediumDate(dateTime.toLocal());
    final timeLabel = TimeOfDay.fromDateTime(dateTime).format(context);
    setState(() {
      _warrantDateTime = dateTime;
      _warrantDateTimeController.text = '$dateLabel · $timeLabel';
    });
  }

  Future<void> _submitPatrolReport() async {
    if (_isSubmitting || !_formKey.currentState!.validate()) return;
    final user = AuthService().currentUser;
    if (user == null || _warrantDateTime == null) {
      setState(
          () => _errorMessage = 'Sesi login atau tanggal surat tidak valid.');
      return;
    }

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    try {
      final report = PatrolReport(
        id: const Uuid().v1(),
        officerId: user.uid,
        warrantDateTime: _warrantDateTime!,
        typeOfPatrol: _typeOfPatrol,
        natureOfPatrol: _natureOfPatrolController.text.trim(),
        isFootPatrol: _isFootPatrol,
        numberOfPersonnel: _numberOfPersonnel,
        patrolRouteId: widget.patrolRouteId ?? '',
      );
      await FirebaseService().addPatrolReport(report);
      if (!mounted) return;
      widget.onReportSubmitted();
      Navigator.pop(context);
    } catch (error) {
      if (mounted) {
        setState(() => _errorMessage = 'Gagal menyimpan laporan: $error');
      }
    } finally {
      if (mounted) setState(() => _isSubmitting = false);
    }
  }
}
