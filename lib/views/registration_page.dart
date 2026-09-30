import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:flutter/material.dart';
import 'package:police_patrol_app/models/user.dart';
import 'package:police_patrol_app/services/auth_service.dart';
import 'package:police_patrol_app/services/firebase_service.dart';

class RegistrationPage extends StatefulWidget {
  const RegistrationPage({super.key});

  @override
  State<RegistrationPage> createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _authService = AuthService();
  final _firebaseService = FirebaseService();
  UserRole _selectedRole = UserRole.Public;
  String _message = '';
  bool _isError = false;
  bool _isRegistering = false;
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Scaffold(
        backgroundColor: const Color(0xFFF2F5F4),
        appBar: AppBar(
          title: const Text('Daftar akun'),
          elevation: 0,
          backgroundColor: Colors.transparent,
          foregroundColor: Colors.blueGrey.shade900,
        ),
        body: SafeArea(
          top: false,
          child: LayoutBuilder(
            builder: (context, constraints) => SingleChildScrollView(
              padding: const EdgeInsets.all(24),
              child: ConstrainedBox(
                constraints:
                    BoxConstraints(minHeight: constraints.maxHeight - 24),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Card(
                      margin: EdgeInsets.zero,
                      elevation: 1,
                      shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12)),
                      child: Padding(
                        padding: const EdgeInsets.all(20),
                        child: Form(
                          key: _formKey,
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              Icon(Icons.person_add_alt_1_outlined,
                                  size: 42, color: Colors.blueGrey.shade800),
                              const SizedBox(height: 12),
                              Text('Buat akun',
                                  textAlign: TextAlign.center,
                                  style: Theme.of(context)
                                      .textTheme
                                      .titleLarge
                                      ?.copyWith(fontWeight: FontWeight.w700)),
                              const SizedBox(height: 6),
                              const Text(
                                  'Akun petugas dan command center perlu disetujui terlebih dahulu.',
                                  textAlign: TextAlign.center,
                                  style: TextStyle(color: Colors.blueGrey)),
                              const SizedBox(height: 24),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autofillHints: const [AutofillHints.email],
                                decoration: const InputDecoration(
                                    labelText: 'Email',
                                    prefixIcon: Icon(Icons.email_outlined),
                                    border: OutlineInputBorder()),
                                validator: (value) {
                                  final email = value?.trim() ?? '';
                                  if (email.isEmpty) return 'Email wajib diisi';
                                  return RegExp(r'^[^\s@]+@[^\s@]+\.[^\s@]+$')
                                          .hasMatch(email)
                                      ? null
                                      : 'Masukkan format email yang valid';
                                },
                              ),
                              const SizedBox(height: 14),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                textInputAction: TextInputAction.done,
                                onFieldSubmitted: (_) => _register(),
                                decoration: InputDecoration(
                                  labelText: 'Kata sandi',
                                  helperText: 'Minimal 6 karakter',
                                  prefixIcon: const Icon(Icons.lock_outline),
                                  border: const OutlineInputBorder(),
                                  suffixIcon: IconButton(
                                    tooltip: _obscurePassword
                                        ? 'Tampilkan kata sandi'
                                        : 'Sembunyikan kata sandi',
                                    icon: Icon(_obscurePassword
                                        ? Icons.visibility_outlined
                                        : Icons.visibility_off_outlined),
                                    onPressed: () => setState(() =>
                                        _obscurePassword = !_obscurePassword),
                                  ),
                                ),
                                validator: (value) => (value?.length ?? 0) < 6
                                    ? 'Kata sandi minimal 6 karakter'
                                    : null,
                              ),
                              const SizedBox(height: 14),
                              DropdownButtonFormField<UserRole>(
                                initialValue: _selectedRole,
                                decoration: const InputDecoration(
                                    labelText: 'Ajukan sebagai',
                                    prefixIcon: Icon(Icons.badge_outlined),
                                    border: OutlineInputBorder()),
                                items: UserRole.values
                                    .map((role) => DropdownMenuItem(
                                        value: role,
                                        child: Text(_roleLabel(role))))
                                    .toList(),
                                onChanged: _isRegistering
                                    ? null
                                    : (role) =>
                                        setState(() => _selectedRole = role!),
                              ),
                              if (_message.isNotEmpty) ...[
                                const SizedBox(height: 16),
                                _StatusMessage(
                                    message: _message, isError: _isError),
                              ],
                              const SizedBox(height: 20),
                              SizedBox(
                                height: 48,
                                child: ElevatedButton(
                                  onPressed: _isRegistering ? null : _register,
                                  child: _isRegistering
                                      ? const SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(
                                              strokeWidth: 2))
                                      : const Text('Daftar'),
                                ),
                              ),
                              const SizedBox(height: 8),
                              TextButton(
                                  onPressed: _isRegistering
                                      ? null
                                      : () => Navigator.pop(context),
                                  child: const Text('Sudah punya akun? Masuk')),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
        ),
      );

  Future<void> _register() async {
    FocusScope.of(context).unfocus();
    if (!_formKey.currentState!.validate()) return;
    final email = _emailController.text.trim().toLowerCase();
    setState(() {
      _isRegistering = true;
      _message = '';
    });
    try {
      final approvedRole = await _firebaseService.getApprovedUserRole(email);
      if (approvedRole == null) {
        await _firebaseService.addPreApprovalRequest(email, _selectedRole);
        _showMessage(
            'Permintaan pendaftaran telah dikirim. Silakan tunggu persetujuan administrator.',
            false);
        return;
      }
      await _authService.registerWithEmailAndPassword(
          email, _passwordController.text, approvedRole);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
          content: Text('Akun berhasil dibuat. Silakan masuk.')));
      Navigator.pop(context);
    } on auth.FirebaseAuthException catch (error) {
      _showMessage(_firebaseAuthMessage(error.code), true);
    } on FirebaseException catch (error) {
      _showMessage(error.message ?? 'Permintaan tidak dapat diproses.', true);
    } catch (_) {
      _showMessage('Pendaftaran gagal. Periksa koneksi lalu coba lagi.', true);
    } finally {
      if (mounted) setState(() => _isRegistering = false);
    }
  }

  void _showMessage(String message, bool isError) {
    if (!mounted) return;
    setState(() {
      _message = message;
      _isError = isError;
    });
  }

  String _roleLabel(UserRole role) => switch (role) {
        UserRole.Officer => 'Petugas patroli',
        UserRole.CommandCenter => 'Command center',
        UserRole.Public => 'Masyarakat',
      };

  String _firebaseAuthMessage(String code) => switch (code) {
        'email-already-in-use' => 'Email ini sudah terdaftar. Silakan masuk.',
        'invalid-email' => 'Format email tidak valid.',
        'weak-password' => 'Kata sandi terlalu lemah.',
        _ => 'Pendaftaran gagal ($code). Silakan coba lagi.',
      };
}

class _StatusMessage extends StatelessWidget {
  const _StatusMessage({required this.message, required this.isError});
  final String message;
  final bool isError;

  @override
  Widget build(BuildContext context) {
    final color = isError ? Colors.red : Colors.green;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
          color: color.shade50, borderRadius: BorderRadius.circular(8)),
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(isError ? Icons.error_outline : Icons.check_circle_outline,
            color: color.shade700),
        const SizedBox(width: 8),
        Expanded(child: Text(message, style: TextStyle(color: color.shade800))),
      ]),
    );
  }
}
