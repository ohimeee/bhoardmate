import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/room.dart';
import '../providers/auth_provider.dart';

class MemberDetailScreen extends StatelessWidget {
  final Room room;
  const MemberDetailScreen({super.key, required this.room});

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final matches = auth.rooms.where((item) => item.id == room.id);
    final allowed = auth.isLoggedIn;
    final ownProfile = !auth.isOwner && auth.currentRoomId == room.id;
    final current = matches.isEmpty ? null : matches.first;
    final name = _display(current?.boarderName);
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6EE),
      appBar: AppBar(
        title: Text(ownProfile ? 'Me' : room.id),
        backgroundColor: const Color(0xFFFDE7D3),
      ),
      body: !allowed
          ? const Center(child: Text('Please log in to view this profile.'))
          : current == null
          ? const Center(child: Text('This room is no longer available.'))
          : ListView(
              padding: const EdgeInsets.all(24),
              children: [
                if (!ownProfile) ...[
                  const SizedBox(height: 24),
                  const Center(
                    child: CircleAvatar(
                      radius: 52,
                      backgroundColor: Color(0xFFFDE7D3),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    name,
                    textAlign: TextAlign.center,
                    style: const TextStyle(fontSize: 22),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Boarder',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.black54),
                  ),
                  const SizedBox(height: 24),
                ],
                Card(
                  color: Colors.white,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        if (ownProfile) ...[
                          Row(
                            children: [
                              const CircleAvatar(
                                radius: 30,
                                backgroundColor: Color(0xFFFDE7D3),
                              ),
                              const SizedBox(width: 16),
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      name,
                                      style: const TextStyle(fontSize: 18),
                                    ),
                                    Text(
                                      'Room ${current.id}',
                                      style: const TextStyle(
                                        color: Colors.black54,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 20),
                          Text('Contact: ${_display(current.contactNumber)}'),
                          const SizedBox(height: 8),
                          Text('Age: ${current.age ?? 'Not provided'}'),
                          const SizedBox(height: 8),
                          Text(
                            'Emergency: ${_display(current.emergencyContactName)}, ${_display(current.emergencyContactNumber)}',
                          ),
                        ] else ...[
                          _field('Room ID', current.id),
                          _field(
                            'Monthly rent',
                            '\u20B1 ${current.monthlyRent.toStringAsFixed(2)}',
                          ),
                          _field('Contact', _display(current.contactNumber)),
                          _field('Age', '${current.age ?? 'Not provided'}'),
                          _field(
                            'Emergency contact',
                            '${_display(current.emergencyContactName)}, ${_display(current.emergencyContactNumber)}',
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
                if (ownProfile) ...[
                  const SizedBox(height: 12),
                  Padding(
                    padding:
                        (Theme.of(context).cardTheme.margin ??
                                const EdgeInsets.all(4))
                            .resolve(Directionality.of(context))
                            .copyWith(top: 0, bottom: 0),
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.black,
                        side: const BorderSide(color: Colors.black),
                        backgroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(48),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                      ),
                      onPressed: () => showDialog<void>(
                        context: context,
                        barrierDismissible: false,
                        builder: (_) => _EditProfileDialog(room: current),
                      ),
                      child: const Text('Edit Profile'),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Card(
                    color: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Landlord',
                            style: TextStyle(color: Colors.black54),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            auth.owner.name,
                            style: const TextStyle(fontSize: 18),
                          ),
                          Text(
                            auth.owner.contactNumber,
                            style: const TextStyle(color: Colors.black54),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  Widget _field(String label, String value) => Padding(
    padding: const EdgeInsets.only(bottom: 8),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: const TextStyle(color: Colors.black54)),
        Text(value, style: const TextStyle(fontSize: 18)),
      ],
    ),
  );

  String _display(String? value) =>
      value == null || value.trim().isEmpty ? 'Not provided' : value;
}

class _EditProfileDialog extends StatefulWidget {
  final Room room;
  const _EditProfileDialog({required this.room});
  @override
  State<_EditProfileDialog> createState() => _EditProfileDialogState();
}

class _EditProfileDialogState extends State<_EditProfileDialog> {
  final _formKey = GlobalKey<FormState>();
  late final List<TextEditingController> _controllers;
  bool _saving = false;
  String? _error;
  @override
  void initState() {
    super.initState();
    final room = widget.room;
    _controllers = [
      room.boarderName,
      room.contactNumber?.replaceAll(' ', ''),
      room.age?.toString(),
      room.emergencyContactName,
      room.emergencyContactNumber?.replaceAll(' ', ''),
    ].map((value) => TextEditingController(text: value ?? '')).toList();
  }

  @override
  void dispose() {
    for (final controller in _controllers) {
      controller.dispose();
    }
    super.dispose();
  }

  String? _optional(int index) => _controllers[index].text.trim().isEmpty
      ? null
      : _controllers[index].text.trim();
  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final matches = auth.rooms.where((room) => room.id == widget.room.id);
    if (!auth.isLoggedIn ||
        auth.isOwner ||
        auth.currentRoomId != widget.room.id ||
        matches.isEmpty) {
      setState(() => _error = 'Please log in to your room again.');
      return;
    }
    final room = matches.first;
    setState(() {
      _saving = true;
      _error = null;
    });
    try {
      await auth.updateRoom(
        Room(
          id: room.id,
          accessCode: room.accessCode,
          monthlyRent: room.monthlyRent,
          boarderName: _controllers[0].text.trim(),
          contactNumber: _optional(1),
          age: int.tryParse(_controllers[2].text.trim()),
          emergencyContactName: _optional(3),
          emergencyContactNumber: _optional(4),
        ),
      );
      if (!mounted) return;
      if (auth.errorMessage != null) {
        setState(() {
          _saving = false;
          _error = auth.errorMessage;
        });
        return;
      }
      setState(() => _saving = false);
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Profile saved.')));
        Navigator.pop(context);
      });
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
    const labels = [
      'Name',
      'Contact number',
      'Age',
      'Emergency contact name',
      'Emergency contact number',
    ];
    return PopScope(
      canPop: !_saving,
      child: AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Edit profile'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                for (var index = 0; index < labels.length; index++)
                  Padding(
                    padding: const EdgeInsets.only(bottom: 16),
                    child: TextFormField(
                      controller: _controllers[index],
                      enabled: !_saving,
                      decoration: InputDecoration(labelText: labels[index]),
                      keyboardType: index == 2
                          ? TextInputType.number
                          : index == 1 || index == 4
                          ? TextInputType.phone
                          : TextInputType.text,
                      validator: (value) {
                        final text = value?.trim() ?? '';
                        if (index == 0 && text.isEmpty) {
                          return 'Name is required';
                        }
                        if ((index == 1 || index == 4) &&
                            text.isNotEmpty &&
                            !RegExp(r'^\d+$').hasMatch(text)) {
                          return 'Use digits only';
                        }
                        if (index == 2 &&
                            text.isNotEmpty &&
                            (int.tryParse(text) == null ||
                                int.parse(text) <= 0)) {
                          return 'Enter a positive whole number';
                        }
                        return null;
                      },
                    ),
                  ),
                if (_error != null)
                  Text(
                    _error!,
                    style: const TextStyle(color: Color(0xFFD9534F)),
                  ),
              ],
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: _saving ? null : () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFF2E6B4F),
              foregroundColor: Colors.white,
            ),
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Saving...' : 'Save'),
          ),
        ],
      ),
    );
  }
}
