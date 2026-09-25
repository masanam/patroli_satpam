import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart' as auth;
import 'package:police_patrol_app/views/dashboard_page.dart';
import 'package:police_patrol_app/viewsCommandCenter/command_center_page.dart';
import 'package:police_patrol_app/services/auth_service.dart';
import 'package:police_patrol_app/services/firebase_service.dart';
import 'package:police_patrol_app/models/user.dart';
import 'package:police_patrol_app/utils/constants.dart';
import 'package:police_patrol_app/widgets/custom_button.dart';

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
      appBar: AppBar(title: Text(APP_TITLE)),
      body: Padding(
        padding: EdgeInsets.all(DEFAULT_PADDING),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Login',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
              SizedBox(height: 20),
              TextFormField(
                decoration: InputDecoration(labelText: 'Email'),
                validator: (val) => val!.isEmpty ? 'Enter an email' : null,
                onChanged: (val) => setState(() => _email = val),
              ),
              SizedBox(height: 10),
              TextFormField(
                decoration: InputDecoration(labelText: 'Password'),
                obscureText: true,
                validator: (val) =>
                    val!.length < 6 ? 'Enter a password 6+ chars long' : null,
                onChanged: (val) => setState(() => _password = val),
              ),
              SizedBox(height: 20),
              CustomButton(
                text: 'Login',
                onPressed: _isLoggingIn ? () {} : () => _login(),
              ),
              if (_isLoggingIn) ...[
                const SizedBox(height: 12),
                const CircularProgressIndicator(),
              ],
              SizedBox(height: 20),
              CustomButton(
                text: 'Register',
                onPressed: () {
                  Navigator.pushNamed(context, '/register');
                },
              ),
              SizedBox(height: 20),
              Text(
                _errorMessage,
                style: TextStyle(color: Colors.red, fontSize: 14.0),
              ),
            ],
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
