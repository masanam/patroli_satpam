import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:police_patrol_app/services/auth_service.dart';
import 'package:police_patrol_app/services/firebase_service.dart';
import 'package:police_patrol_app/utils/constants.dart';
import 'package:police_patrol_app/widgets/custom_button.dart';
import 'package:police_patrol_app/models/user.dart';

class RegistrationPage extends StatefulWidget {
  @override
  _RegistrationPageState createState() => _RegistrationPageState();
}

class _RegistrationPageState extends State<RegistrationPage> {
  final AuthService _authService = AuthService();
  final FirebaseService _firebaseService = FirebaseService();
  final _formKey = GlobalKey<FormState>();
  String _email = '';
  String _password = '';
  UserRole _selectedRole = UserRole.Public; // Default to 'Public'
  String _errorMessage = '';
  bool _isRegistering = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Register')),
      body: Padding(
        padding: EdgeInsets.all(DEFAULT_PADDING),
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text('Create an Account',
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
              DropdownButtonFormField<UserRole>(
                decoration: InputDecoration(labelText: 'Role'),
                value: _selectedRole,
                items: UserRole.values.map((UserRole role) {
                  return DropdownMenuItem<UserRole>(
                    value: role,
                    child: Text(role.toString().split('.').last),
                  );
                }).toList(),
                onChanged: (UserRole? newRole) {
                  setState(() {
                    _selectedRole = newRole!;
                  });
                },
              ),
              SizedBox(height: 20),
              CustomButton(
                text: 'Register',
                onPressed: _isRegistering ? () {} : () => _register(),
              ),
              if (_isRegistering) ...[
                const SizedBox(height: 12),
                const CircularProgressIndicator(),
              ],
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

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    final email = _email.trim().toLowerCase();
    setState(() {
      _isRegistering = true;
      _errorMessage = '';
    });

    try {
      final isApproved = await _firebaseService.isUserPreApproved(email);

      if (!isApproved) {
        await _firebaseService.addPreApprovalRequest(email, _selectedRole);
        if (!mounted) return;
        setState(() {
          _errorMessage =
              'Your registration request was submitted for approval.';
        });
        return;
      }

      final user = await _authService.registerWithEmailAndPassword(
        email,
        _password,
        _selectedRole,
      );
      if (user == null) {
        if (mounted) {
          setState(() {
            _errorMessage = 'Registration failed. Please try again.';
          });
        }
        return;
      }

      if (mounted) Navigator.pop(context);
    } on FirebaseException catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = error.message ?? 'Firebase request failed.';
      });
    } catch (error) {
      if (!mounted) return;
      setState(() {
        _errorMessage = 'Registration failed: $error';
      });
    } finally {
      if (mounted) {
        setState(() => _isRegistering = false);
      }
    }
  }
}
