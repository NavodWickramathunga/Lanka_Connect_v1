import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../utils/firestore_refs.dart';
import '../../utils/user_roles.dart';
import '../../utils/validators.dart';

class AuthScreen extends StatefulWidget {
  const AuthScreen({super.key});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLogin = true;
  bool _loading = false;
  String _role = UserRoles.seeker;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final form = _formKey.currentState;
    if (form == null || !form.validate()) {
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
        );
      } else {
        final credential = await FirebaseAuth.instance
            .createUserWithEmailAndPassword(
              email: _emailController.text.trim(),
              password: _passwordController.text,
            );
        await _createUserProfile(credential.user);
      }
    } on FirebaseAuthException catch (e) {
      String errorMessage;
      switch (e.code) {
        case 'weak-password':
          errorMessage = 'The password provided is too weak.';
          break;
        case 'email-already-in-use':
          errorMessage = 'An account already exists for this email.';
          break;
        case 'invalid-email':
          errorMessage = 'The email address is not valid.';
          break;
        case 'user-not-found':
          errorMessage = 'No user found with this email.';
          break;
        case 'wrong-password':
          errorMessage = 'Incorrect password.';
          break;
        default:
          errorMessage = e.message ?? 'Authentication failed';
      }
      setState(() {
        _error = errorMessage;
      });
    } catch (e) {
      setState(() {
        _error = 'Something went wrong. Please try again.';
      });
    } finally {
      if (mounted) {
        setState(() {
          _loading = false;
        });
      }
    }
  }

  Future<void> _createUserProfile(User? user) async {
    if (user == null) return;

    final email = user.email ?? _emailController.text.trim();
    final emailName = _nameFromEmail(email);

    final doc = FirestoreRefs.users().doc(user.uid);
    final data = {
      'role': _role,
      'name': emailName,
      'email': email,
      'contact': '',
      'district': '',
      'city': '',
      'skills': <String>[],
      'bio': '',
      'imageUrl': '',
      'createdAt': FieldValue.serverTimestamp(),
    };
    await doc.set(data, SetOptions(merge: true));
  }

  String _nameFromEmail(String email) {
    final atIndex = email.indexOf('@');
    if (atIndex <= 0) return '';
    final raw = email.substring(0, atIndex).trim();
    if (raw.isEmpty) return '';

    return raw
        .replaceAll(RegExp(r'[._-]+'), ' ')
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .map((part) {
          final first = part.substring(0, 1).toUpperCase();
          final rest = part.length > 1 ? part.substring(1).toLowerCase() : '';
          return '$first$rest';
        })
        .join(' ');
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_isLogin ? 'Login' : 'Sign Up')),
      body: Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextFormField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(labelText: 'Email'),
                    validator: (value) => Validators.emailField(value),
                  ),
                  const SizedBox(height: 12),
                  TextFormField(
                    controller: _passwordController,
                    decoration: const InputDecoration(labelText: 'Password'),
                    obscureText: true,
                    validator: (value) =>
                        Validators.passwordField(value, isLogin: _isLogin),
                  ),
                  const SizedBox(height: 12),
                  if (!_isLogin)
                    DropdownButtonFormField<String>(
                      value: _role,
                      items: const [
                        DropdownMenuItem(
                          value: UserRoles.seeker,
                          child: Text('Service Seeker'),
                        ),
                        DropdownMenuItem(
                          value: UserRoles.provider,
                          child: Text('Service Provider'),
                        ),
                      ],
                      onChanged: (value) {
                        if (value == null) return;
                        setState(() {
                          _role = value;
                        });
                      },
                      decoration: const InputDecoration(
                        labelText: 'Select role',
                      ),
                    ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Text(_error!, style: const TextStyle(color: Colors.red)),
                  ],
                  const SizedBox(height: 20),
                  ElevatedButton(
                    onPressed: _loading ? null : _submit,
                    child: Text(
                      _loading
                          ? 'Please wait...'
                          : _isLogin
                          ? 'Login'
                          : 'Create account',
                    ),
                  ),
                  const SizedBox(height: 12),
                  TextButton(
                    onPressed: _loading
                        ? null
                        : () {
                            setState(() {
                              _isLogin = !_isLogin;
                              _error = null;
                            });
                          },
                    child: Text(
                      _isLogin
                          ? 'Need an account? Sign up'
                          : 'Already have an account? Login',
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
}
