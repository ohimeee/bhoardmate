import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../models/owner.dart';
import '../providers/auth_provider.dart';
import '../widgets/info_card.dart';

class OwnerProfileScreen extends StatefulWidget {
  // Connect a provider action here once owner updates are supported.
  final Future<void> Function(Owner owner)? onSave;
  const OwnerProfileScreen({super.key, this.onSave});

  @override
  State<OwnerProfileScreen> createState() => _OwnerProfileScreenState();
}

class _OwnerProfileScreenState extends State<OwnerProfileScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _name;
  late final TextEditingController _phone;
  bool _editing = false;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _name = TextEditingController();
    _phone = TextEditingController();
  }

  @override
  void dispose() {
    _name.dispose();
    _phone.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving ||
        widget.onSave == null ||
        !_formKey.currentState!.validate()) {
      return;
    }
    final auth = context.read<AuthProvider>();
    final owner = auth.owner;
    if (!auth.isLoggedIn || !auth.isOwner || owner == null) return;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await widget.onSave!(
        Owner(
          id: owner.id,
          email: owner.email,
          name: _name.text.trim(),
          contactNumber: _phone.text.trim(),
        ),
      );
      if (!mounted) return;
      setState(() {
        _saving = false;
        _editing = false;
      });
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Profile saved.')));
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Could not save profile. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final owner = auth.owner;
    return PopScope(
      canPop: !_saving,
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Me'),
          backgroundColor: AppColors.members,
          foregroundColor: AppColors.membersDark,
        ),
        body: !auth.isLoggedIn || !auth.isOwner
            ? const Center(
                child: Text('Please log in as the owner to view this profile.'),
              )
            // owner info still loading from Firestore
            : owner == null
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(24),
                children: [
                  const Center(
                    child: CircleAvatar(
                      radius: 48,
                      backgroundColor: AppColors.members,
                      child: Icon(
                        Icons.person,
                        size: 48,
                        color: AppColors.membersDark,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    owner.name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const Text(
                    'Landlord / landlady',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: AppColors.textLight),
                  ),
                  const SizedBox(height: 24),
                  InfoCard(
                    rows: {
                      'Contact': owner.contactNumber,
                      'Email': owner.email,
                    },
                  ),
                  const SizedBox(height: 12),
                  if (!_editing)
                    OutlinedButton(
                      onPressed: widget.onSave == null
                          ? null
                          : () {
                              _name.text = owner.name;
                              _phone.text = owner.contactNumber.replaceAll(
                                ' ',
                                '',
                              );
                              setState(() {
                                _editing = true;
                                _error = null;
                              });
                            },
                      child: const Text('Edit profile'),
                    ),
                  if (widget.onSave == null)
                    const Text('Profile editing is not available yet.'),
                  if (_editing)
                    Form(
                      key: _formKey,
                      child: Column(
                        children: [
                          TextFormField(
                            controller: _name,
                            enabled: !_saving,
                            decoration: const InputDecoration(
                              labelText: 'Name',
                            ),
                            validator: (value) =>
                                value == null || value.trim().isEmpty
                                ? 'Name is required'
                                : null,
                          ),
                          const SizedBox(height: 16),
                          TextFormField(
                            controller: _phone,
                            enabled: !_saving,
                            keyboardType: TextInputType.phone,
                            decoration: const InputDecoration(
                              labelText: 'Contact number',
                            ),
                            validator: (value) =>
                                value == null ||
                                    !RegExp(r'^\d+$').hasMatch(value.trim())
                                ? 'Enter a phone number using digits only'
                                : null,
                          ),
                          if (_error != null)
                            Text(
                              _error!,
                              style: const TextStyle(color: Color(0xFFD9534F)),
                            ),
                          const SizedBox(height: 16),
                          Row(
                            children: [
                              TextButton(
                                onPressed: _saving
                                    ? null
                                    : () => setState(() => _editing = false),
                                child: const Text('Cancel'),
                              ),
                              FilledButton(
                                onPressed: _saving ? null : _save,
                                child: Text(_saving ? 'Saving...' : 'Save'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                ],
              ),
      ),
    );
  }
}
