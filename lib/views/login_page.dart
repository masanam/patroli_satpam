import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:police_patrol_app/views/dashboard_page.dart';
import 'package:police_patrol_app/viewsCommandCenter/command_center_page.dart';
import 'package:police_patrol_app/services/auth_service.dart';
import 'package:police_patrol_app/services/firebase_service.dart';
import 'package:police_patrol_app/models/user.dart';
import 'package:police_patrol_app/utils/constants.dart';

class LoginPage extends StatefulWidget {
  @override
  _LoginPageState createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final AuthService _authService = AuthService();
  final FirebaseService _firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  String _errorMessage = '';
  bool _isLoggingIn = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF2F5F4),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) => SingleChildScrollView(
            child: ConstrainedBox(
              constraints: BoxConstraints(minHeight: constraints.maxHeight),
              child: IntrinsicHeight(
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 440),
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 64,
                            height: 64,
                            decoration: BoxDecoration(
                              color: Colors.blueGrey.shade800,
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: const Icon(
                              Icons.local_police_outlined,
                              color: Colors.white,
                              size: 34,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            APP_TITLE,
                            textAlign: TextAlign.center,
                            style: Theme.of(context)
                                .textTheme
                                .headlineSmall
                                ?.copyWith(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          const Text(
                            'Masuk untuk melanjutkan tugas patroli',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: Colors.blueGrey),
                          ),
                          const SizedBox(height: 24),
                          Card(
                            margin: EdgeInsets.zero,
                            elevation: 1,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Padding(
                              padding: const EdgeInsets.all(20),
                              child: Form(
                                key: _formKey,
                                child: Column(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.stretch,
                                  children: [
                                    Text(
                                      'Masuk',
                                      style: Theme.of(context)
                                          .textTheme
                                          .titleLarge
                                          ?.copyWith(
                                              fontWeight: FontWeight.w700),
                                    ),
                                    const SizedBox(height: 18),
                                    TextFormField(
                                      keyboardType: TextInputType.emailAddress,
                                      textInputAction: TextInputAction.next,
                                      decoration: const InputDecoration(
                                        labelText: 'Email',
                                        prefixIcon: Icon(Icons.email_outlined),
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (value) =>
                                          value == null || value.trim().isEmpty
                                              ? 'Email wajib diisi'
                                              : null,
                                      onChanged: (value) =>
                                          setState(() => _email = value.trim()),
                                    ),
                                    const SizedBox(height: 14),
                                    TextFormField(
                                      obscureText: true,
                                      textInputAction: TextInputAction.done,
                                      onFieldSubmitted: (_) => _login(),
                                      decoration: const InputDecoration(
                                        labelText: 'Kata sandi',
                                        prefixIcon: Icon(Icons.lock_outline),
                                        border: OutlineInputBorder(),
                                      ),
                                      validator: (value) =>
                                          value == null || value.length < 6
                                              ? 'Masukkan minimal 6 karakter'
                                              : null,
                                      onChanged: (value) =>
                                          setState(() => _password = value),
                                    ),
                                    if (_errorMessage.isNotEmpty) ...[
                                      const SizedBox(height: 14),
                                      Container(
                                        padding: const EdgeInsets.all(12),
                                        decoration: BoxDecoration(
                                          color: Colors.red.shade50,
                                          borderRadius:
                                              BorderRadius.circular(6),
                                        ),
                                        child: Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Icon(Icons.error_outline,
                                                color: Colors.red.shade700),
                                            const SizedBox(width: 8),
                                            Expanded(
                                              child: Text(
                                                _errorMessage,
                                                style: TextStyle(
                                                    color: Colors.red.shade800),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                    const SizedBox(height: 20),
                                    SizedBox(
                                      height: 48,
                                      child: ElevatedButton(
                                        onPressed: _isLoggingIn ? null : _login,
                                        child: _isLoggingIn
                                            ? const SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                  strokeWidth: 2,
                                                ),
                                              )
                                            : const Text('Masuk'),
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    TextButton(
                                      onPressed: _isLoggingIn
                                          ? null
                                          : () => Navigator.pushNamed(
                                              context, '/register'),
                                      child: const Text('Buat akun'),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
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
    );
  }

  Future<void> _login() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoggingIn = true;
      _errorMessage = '';
    });

    try {
      final user = await _authService.signInWithEmailAndPassword(
        _email,
        _password,
      );
      if (user == null) {
        throw StateError('Firebase returned no user.');
      }

      final userDetails = await _firebaseService.getUser(user.uid);
      if (!mounted) return;
      if (userDetails?.role == UserRole.CommandCenter) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => CommandCenterPage()),
        );
      } else {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(builder: (context) => DashboardPage()),
        );
      }
    } on auth.FirebaseAuthException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = _firebaseAuthMessage(error.code);
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Login failed: $error';
      });
    } finally {
      if (mounted) {
        setState(() => _isLoggingIn = false);
      }
    }
  }

  String _firebaseAuthMessage(String code) {
    switch (code) {
      case 'invalid-credential':
      case 'wrong-password':
      case 'user-not-found':
        return 'Email atau password salah, atau akun belum terdaftar di Firebase Authentication.';
      case 'invalid-email':
        return 'Format email tidak valid.';
      case 'user-disabled':
        return 'Akun ini dinonaktifkan.';
      case 'too-many-requests':
        return 'Terlalu banyak percobaan. Coba lagi beberapa saat.';
      default:
        return 'Login gagal ($code). Periksa konfigurasi Firebase dan akun Authentication.';
    }
  }
}
