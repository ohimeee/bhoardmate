import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../app_theme.dart';
import '../models/concern.dart';
import '../providers/auth_provider.dart';
import '../providers/concern_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/status_chip.dart';

class ConcernsScreen extends StatefulWidget {
  const ConcernsScreen({super.key});

  @override
  State<ConcernsScreen> createState() => _ConcernsScreenState();
}

class _ConcernsScreenState extends State<ConcernsScreen> {
  bool _loading = true;
  bool _busy = false;
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
    if (!auth.isLoggedIn || (!auth.isOwner && auth.currentRoomId == null)) {
      setState(() {
        _loading = false;
        _error = 'Please log in again to view your concerns.';
      });
      return;
    }
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<ConcernProvider>().loadConcerns(
        roomId: auth.isOwner ? null : auth.currentRoomId,
      );
      if (!mounted) return;
      setState(() => _loading = false);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Could not load concerns. Please try again.';
      });
    }
  }

  void _message(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  Future<void> _report() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => const _ReportConcernDialog(),
    );
    if (!mounted) return;
  }

  Future<void> _change(Concern concern, {bool remove = false}) async {
    if (_busy || concern.id == null) return;
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn ||
        (!auth.isOwner && (!remove || auth.currentRoomId != concern.roomId))) {
      return;
    }
    setState(() => _busy = true);
    if (remove) {
      final confirmed = await showDialog<bool>(
        context: context,
        builder: (dialogContext) => AlertDialog(
          title: const Text('Remove concern?'),
          content: Text('Remove "${concern.title}"? This cannot be undone.'),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancel'),
            ),
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Remove'),
            ),
          ],
        ),
      );
      if (!mounted) return;
      if (confirmed != true) {
        setState(() => _busy = false);
        return;
      }
    }
    final provider = context.read<ConcernProvider>();
    try {
      if (remove) {
        await provider.deleteConcern(concern.id!);
      } else {
        await provider.toggleStatus(concern.id!);
      }
      if (!mounted) return;
      _message(
        provider.errorMessage ??
            (remove
                ? 'Concern removed.'
                : concern.status == 'done'
                ? 'Concern marked pending.'
                : 'Concern marked done.'),
      );
    } catch (_) {
      if (!mounted) return;
      _message('Could not save the change. Please try again.');
    }
    if (!mounted) return;
    setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<ConcernProvider>();
    final concerns = provider.concerns
        .where(
          (concern) =>
              auth.isLoggedIn &&
              (auth.isOwner || concern.roomId == auth.currentRoomId),
        )
        .toList();
    final error =
        !auth.isLoggedIn || (!auth.isOwner && auth.currentRoomId == null)
        ? 'Please log in again to view your concerns.'
        : _error ?? provider.errorMessage;
    final loading = _loading || provider.isLoading;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Concerns'),
        backgroundColor: AppColors.concerns,
        foregroundColor: AppColors.concernsDark,
        actions: [
          IconButton(
            tooltip: 'Refresh concerns',
            onPressed: loading || _busy ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton:
          auth.isLoggedIn && !auth.isOwner && auth.currentRoomId != null
          ? FloatingActionButton.extended(
              onPressed: loading || _busy || error != null ? null : _report,
              icon: const Icon(Icons.add),
              label: const Text('Report a concern'),
            )
          : null,
      body: error != null
          ? EmptyState(
              icon: Icons.error_outline,
              title: error,
              buttonLabel: 'Retry',
              onPressed: loading ? null : _load,
            )
          : loading
          ? const Center(child: CircularProgressIndicator())
          : concerns.isEmpty
          ? const EmptyState(
              icon: Icons.chat_bubble_outline,
              title: 'No concerns yet',
              message: 'Reported concerns will appear here.',
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              itemCount: concerns.length,
              itemBuilder: (context, index) {
                final concern = concerns[index];
                final done = concern.status == 'done';
                final date = DateTime.tryParse(concern.createdAt)?.toLocal();
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            if (auth.isOwner)
                              Checkbox(
                                value: done,
                                semanticLabel:
                                    'Mark ${concern.title} ${done ? 'pending' : 'done'}',
                                onChanged: _busy || concern.id == null
                                    ? null
                                    : (_) => _change(concern),
                              ),
                            Expanded(
                              child: Text(
                                concern.title,
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            IconButton(
                              tooltip: 'Remove concern',
                              onPressed: _busy || concern.id == null
                                  ? null
                                  : () => _change(concern, remove: true),
                              icon: const Icon(Icons.delete_outline),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(concern.description),
                        const SizedBox(height: 12),
                        Text('Room: ${concern.roomId}'),
                        if (date != null)
                          Text(
                            'Reported: ${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}',
                          ),
                        const SizedBox(height: 12),
                        StatusChip(status: concern.status),
                      ],
                    ),
                  ),
                );
              },
            ),
    );
  }
}

class _ReportConcernDialog extends StatefulWidget {
  const _ReportConcernDialog();

  @override
  State<_ReportConcernDialog> createState() => _ReportConcernDialogState();
}

class _ReportConcernDialogState extends State<_ReportConcernDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController();
    _descriptionController = TextEditingController();
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    final roomId = auth.currentRoomId;
    if (!auth.isLoggedIn || auth.isOwner || roomId == null) {
      setState(() => _error = 'Please log in as a boarder again.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final provider = context.read<ConcernProvider>();
    try {
      await provider.addConcern(
        Concern(
          roomId: roomId,
          title: _titleController.text.trim(),
          description: _descriptionController.text.trim(),
          createdAt: DateTime.now().toIso8601String(),
        ),
      );
      if (!mounted) return;
      if (provider.errorMessage != null) {
        setState(() {
          _saving = false;
          _error = provider.errorMessage;
        });
        return;
      }
      setState(() => _saving = false);
      // Let PopScope rebuild before closing after a save.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Concern reported.')));
        Navigator.pop(context);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Could not report concern. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: AlertDialog(
        backgroundColor: Colors.white,
        title: const Text('Report a concern'),
        content: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  controller: _titleController,
                  enabled: !_saving,
                  decoration: const InputDecoration(labelText: 'Title'),
                  textCapitalization: TextCapitalization.sentences,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Title is required'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _descriptionController,
                  enabled: !_saving,
                  decoration: const InputDecoration(labelText: 'Description'),
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 3,
                  maxLines: 6,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Description is required'
                      : null,
                ),
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
            onPressed: _saving ? null : _submit,
            child: Text(_saving ? 'Saving...' : 'Submit'),
          ),
        ],
      ),
    );
  }
}
