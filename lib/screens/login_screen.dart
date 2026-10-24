import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../providers/auth_provider.dart';
import 'main_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _roomId;
  late final TextEditingController _code;
  late final TextEditingController _email;
  late final TextEditingController _password;

  bool _ownerMode = false;
  // true while we check if someone is still logged in
  bool _checking = true;
  bool _loading = false;

  @override
  void initState() {
    super.initState();
    _roomId = TextEditingController();
    _code = TextEditingController();
    _email = TextEditingController();
    _password = TextEditingController();
    WidgetsBinding.instance.addPostFrameCallback((_) => _checkSession());
  }

  @override
  void dispose() {
    _roomId.dispose();
    _code.dispose();
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

  // skip the login screen if Firebase still has the account
  Future<void> _checkSession() async {
    final auth = context.read<AuthProvider>();
    await auth.loadSession();
    if (!mounted) return;
    if (auth.isLoggedIn) {
      _goToMain();
    } else {
      setState(() => _checking = false);
    }
  }

  void _goToMain() {
    Navigator.pushReplacement(
      context,
      MaterialPageRoute(builder: (context) => const MainScreen()),
    );
  }

  Future<void> _login() async {
    if (_loading || !_formKey.currentState!.validate()) return;
    FocusScope.of(context).unfocus();
    setState(() => _loading = true);
    final auth = context.read<AuthProvider>();
    final ok = _ownerMode
        ? await auth.loginOwner(_email.text, _password.text)
        : await auth.loginBoarder(_roomId.text, _code.text);
    if (!mounted) return;
    setState(() => _loading = false);
    if (ok) _goToMain();
  }

  void _switchMode() {
    // the old error belongs to the other form
    context.read<AuthProvider>().clearError();
    setState(() {
      _ownerMode = !_ownerMode;
      _formKey.currentState?.reset();
    });
  }

  @override
  Widget build(BuildContext context) {
    final error = context.watch<AuthProvider>().errorMessage;

    if (_checking) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Icon(
                    Icons.house_rounded,
                    size: 72,
                    color: AppColors.primary,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'BHoardMate',
                    textAlign: TextAlign.center,
                    style: TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    _ownerMode
                        ? 'Owner login'
                        : 'Log in with your room ID and access code',
                    textAlign: TextAlign.center,
                    style: const TextStyle(color: AppColors.textLight),
                  ),
                  const SizedBox(height: 32),
                  if (_ownerMode) ...[
                    TextFormField(
                      controller: _email,
                      enabled: !_loading,
                      keyboardType: TextInputType.emailAddress,
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Email is required';
                        }
                        if (!value.contains('@')) return 'Enter a valid email';
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _password,
                      enabled: !_loading,
                      obscureText: true,
                      decoration: const InputDecoration(
                        labelText: 'Password',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Password is required';
                        }
                        return null;
                      },
                    ),
                  ] else ...[
                    TextFormField(
                      controller: _roomId,
                      enabled: !_loading,
                      textCapitalization: TextCapitalization.characters,
                      decoration: const InputDecoration(
                        labelText: 'Room ID',
                        hintText: 'BH01-RM2',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Room ID is required';
                        }
                        // same format as the Rooms screen
                        final id = value.trim().toUpperCase();
                        if (!RegExp(r'^BH\d+-RM\d+$').hasMatch(id)) {
                          return 'Use a room ID like BH01-RM2';
                        }
                        return null;
                      },
                    ),
                    const SizedBox(height: 16),
                    TextFormField(
                      controller: _code,
                      enabled: !_loading,
                      obscureText: true,
                      keyboardType: TextInputType.number,
                      decoration: const InputDecoration(
                        labelText: 'Access code',
                        border: OutlineInputBorder(),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Access code is required';
                        }
                        return null;
                      },
                    ),
                  ],
                  const SizedBox(height: 16),
                  if (error != null && !_loading)
                    Text(
                      error,
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: AppColors.unpaidText),
                    ),
                  const SizedBox(height: 16),
                  ElevatedButton(
                    onPressed: _loading ? null : _login,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _loading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Log in'),
                  ),
                  const SizedBox(height: 8),
                  TextButton(
                    onPressed: _loading ? null : _switchMode,
                    child: Text(
                      _ownerMode
                          ? 'Boarder? Log in with your room ID'
                          : 'Owner? Log in as admin',
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
