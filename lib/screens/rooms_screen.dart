import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../models/room.dart';
import '../providers/auth_provider.dart';
import '../widgets/empty_state.dart';

class RoomsScreen extends StatefulWidget {
  const RoomsScreen({super.key});
  @override
  State<RoomsScreen> createState() => _RoomsScreenState();
}

class _RoomsScreenState extends State<RoomsScreen> {
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) _load();
    });
  }

  Future<void> _load() async {
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn || !auth.isOwner) {
      setState(() => _loading = false);
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await auth.loadRooms();
      if (!mounted) return;
      setState(() => _error = auth.errorMessage);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not load rooms. Please try again.');
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final allowed = auth.isLoggedIn && auth.isOwner;
    final error = _error ?? auth.errorMessage;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Rooms'),
        backgroundColor: AppColors.rooms,
        foregroundColor: AppColors.roomsDark,
      ),
      floatingActionButton: allowed
          ? FloatingActionButton.extended(
              heroTag: 'rooms-add-room',
              onPressed: _loading || error != null
                  ? null
                  : () => showDialog<void>(
                      context: context,
                      barrierDismissible: false,
                      builder: (_) => const _RoomDialog(),
                    ),
              icon: const Icon(Icons.add),
              label: const Text('Add room'),
            )
          : null,
      body: !allowed
          ? const Center(child: Text('Only the owner can manage rooms.'))
          : _loading
          ? const Center(child: CircularProgressIndicator())
          : error != null
          ? EmptyState(
              icon: Icons.error_outline,
              title: error,
              buttonLabel: 'Retry',
              onPressed: _load,
            )
          : auth.rooms.isEmpty
          ? const EmptyState(
              icon: Icons.meeting_room_outlined,
              title: 'No rooms yet',
              message: 'Add a room to get started.',
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: auth.rooms.length,
              itemBuilder: (context, index) {
                final room = auth.rooms[index];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          room.id,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          room.boarderName?.trim().isNotEmpty == true
                              ? room.boarderName!
                              : 'Vacant room',
                        ),
                        Text('Code: ${room.accessCode}'),
                        Text(
                          'Monthly rent: \u20B1 ${room.monthlyRent.toStringAsFixed(2)}',
                        ),
                        const SizedBox(height: 8),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.end,
                          children: [
                            OutlinedButton(
                              onPressed: () => showDialog<void>(
                                context: context,
                                barrierDismissible: false,
                                builder: (_) =>
                                    _RoomDialog(room: room, editRent: true),
                              ),
                              child: const Text('Edit rent'),
                            ),
                            const SizedBox(width: 8),
                            OutlinedButton(
                              onPressed: () => showDialog<void>(
                                context: context,
                                barrierDismissible: false,
                                builder: (_) => _RoomDialog(room: room),
                              ),
                              child: const Text('Reset code'),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _RoomDialog extends StatefulWidget {
  final Room? room;
  final bool editRent;
  const _RoomDialog({this.room, this.editRent = false});
  @override
  State<_RoomDialog> createState() => _RoomDialogState();
}

class _RoomDialogState extends State<_RoomDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _id;
  late final TextEditingController _code;
  late final TextEditingController _rent;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _id = TextEditingController();
    _code = TextEditingController();
    _rent = TextEditingController(
      text: widget.editRent ? widget.room!.monthlyRent.toString() : '',
    );
  }

  @override
  void dispose() {
    _id.dispose();
    _code.dispose();
    _rent.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn || !auth.isOwner) {
      setState(() => _error = 'Please log in as the owner again.');
      return;
    }
    final room = widget.room;
    setState(() {
      _saving = true;
      _error = null;
    });
    if (room != null && !widget.editRent) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Reset access code?'),
          content: Text(
            'Reset ${room.id}? This clears the boarder name, contact, age and emergency information. The room ID and rent stay the same.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Reset'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (confirmed != true) {
        setState(() => _saving = false);
        return;
      }
    }
    if (!auth.isLoggedIn || !auth.isOwner) {
      setState(() {
        _saving = false;
        _error = 'Please log in as the owner again.';
      });
      return;
    }
    try {
      if (room == null) {
        await auth.addRoom(
          Room(
            id: _id.text.trim().toUpperCase(),
            accessCode: _code.text.trim(),
            monthlyRent: double.parse(_rent.text.trim()),
          ),
        );
      } else if (widget.editRent) {
        final matches = auth.rooms.where((item) => item.id == room.id);
        if (matches.isEmpty) throw StateError('Room no longer exists');
        final current = matches.first;
        await auth.updateRoom(
          Room(
            id: current.id,
            accessCode: current.accessCode,
            monthlyRent: double.parse(_rent.text.trim()),
            boarderName: current.boarderName,
            contactNumber: current.contactNumber,
            age: current.age,
            emergencyContactName: current.emergencyContactName,
            emergencyContactNumber: current.emergencyContactNumber,
          ),
        );
      } else {
        final matches = auth.rooms.where((item) => item.id == room.id);
        if (matches.isEmpty) throw StateError('Room no longer exists');
        await auth.resetAccessCode(room.id, _code.text.trim());
      }
      if (!mounted) return;
      // the provider clears errorMessage when the change worked
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
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              room == null
                  ? 'Room added.'
                  : widget.editRent
                  ? 'Monthly rent updated.'
                  : 'Access code reset. Boarder information cleared.',
            ),
          ),
        );
        Navigator.pop(context);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Could not save the room. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final room = widget.room;
    return PopScope(
      canPop: !_saving,
      child: AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          room == null
              ? 'Add room'
              : widget.editRent
              ? 'Edit rent for ${room.id}'
              : 'Reset code for ${room.id}',
        ),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (room == null) ...[
                  TextFormField(
                    controller: _id,
                    enabled: !_saving,
                    decoration: const InputDecoration(labelText: 'Room ID'),
                    textCapitalization: TextCapitalization.characters,
                    validator: (value) {
                      final id = value?.trim().toUpperCase() ?? '';
                      if (!RegExp(r'^BH\d+-RM\d+$').hasMatch(id)) {
                        return 'Use a room ID like BH01-RM5';
                      }
                      if (context.read<AuthProvider>().rooms.any(
                        (item) => item.id.toUpperCase() == id,
                      )) {
                        return 'Room ID already exists';
                      }
                      return null;
                    },
                  ),
                  const SizedBox(height: 16),
                ],
                if (!widget.editRent)
                  TextFormField(
                    controller: _code,
                    enabled: !_saving,
                    decoration: InputDecoration(
                      labelText: room == null
                          ? 'Access code'
                          : 'New access code',
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Access code is required';
                      }
                      final matches = context.read<AuthProvider>().rooms.where(
                        (item) => item.id == room?.id,
                      );
                      if (room != null &&
                          matches.isNotEmpty &&
                          value.trim() == matches.first.accessCode) {
                        return 'Choose a different access code';
                      }
                      return null;
                    },
                  ),
                if (room == null || widget.editRent) ...[
                  const SizedBox(height: 16),
                  TextFormField(
                    controller: _rent,
                    enabled: !_saving,
                    decoration: const InputDecoration(
                      labelText: 'Monthly rent',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: (value) {
                      final rent = double.tryParse(value?.trim() ?? '');
                      if (rent == null || !rent.isFinite || rent <= 0) {
                        return 'Enter a positive monthly rent';
                      }
                      return null;
                    },
                  ),
                ],
                if (_error != null) ...[
                  const SizedBox(height: 16),
                  Text(
                    _error!,
                    style: const TextStyle(color: Color(0xFFD9534F)),
                  ),
                ],
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
            onPressed: _saving ? null : _save,
            child: Text(
              _saving
                  ? 'Saving...'
                  : room == null
                  ? 'Add'
                  : widget.editRent
                  ? 'Save'
                  : 'Continue',
            ),
          ),
        ],
      ),
    );
  }
}
