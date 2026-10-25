import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../app_theme.dart';
import '../models/announcement.dart';
import '../providers/announcement_provider.dart';
import '../providers/auth_provider.dart';
import '../providers/holiday_provider.dart';
import '../widgets/empty_state.dart';
import '../widgets/holiday_section.dart';

class AnnouncementsScreen extends StatefulWidget {
  const AnnouncementsScreen({super.key});
  @override
  State<AnnouncementsScreen> createState() => _AnnouncementsScreenState();
}

class _AnnouncementsScreenState extends State<AnnouncementsScreen> {
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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AnnouncementProvider>().loadAnnouncements();
    } catch (_) {
      if (!mounted) return;
      setState(
        () => _error = 'Could not load announcements. Please try again.',
      );
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  // refresh button also reloads the holidays, so going offline
  // and tapping it shows the saved list (no-internet demo)
  void _refresh() {
    context.read<HolidayProvider>().loadHolidays();
    _load();
  }

  Future<void> _edit([Announcement? announcement]) async {
    if (_busy || !context.read<AuthProvider>().isOwner) return;
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (_) => _AnnouncementDialog(announcement: announcement),
    );
  }

  Future<void> _remove(Announcement announcement) async {
    if (_busy ||
        announcement.id == null ||
        !context.read<AuthProvider>().isOwner) {
      return;
    }
    setState(() => _busy = true);
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Remove announcement?'),
        content: Text('Remove "${announcement.title}"? This cannot be undone.'),
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
    if (confirmed == true && context.read<AuthProvider>().isOwner) {
      final provider = context.read<AnnouncementProvider>();
      String message;
      try {
        await provider.deleteAnnouncement(announcement.id!);
        if (!mounted) return;
        message = provider.errorMessage ?? 'Announcement removed.';
      } catch (_) {
        if (!mounted) return;
        message = 'Could not remove announcement. Please try again.';
      }
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    }
    setState(() => _busy = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    final provider = context.watch<AnnouncementProvider>();
    final loading = _loading || provider.isLoading;
    final error = _error ?? provider.errorMessage;
    final announcements = [...provider.announcements]
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return Scaffold(
      appBar: AppBar(
        title: const Text('Announcements'),
        backgroundColor: AppColors.announcements,
        foregroundColor: AppColors.announcementsDark,
        actions: [
          IconButton(
            tooltip: 'Refresh announcements',
            onPressed: loading || _busy ? null : _refresh,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      floatingActionButton: auth.isLoggedIn && auth.isOwner
          ? FloatingActionButton.extended(
              onPressed: loading || _busy || error != null
                  ? null
                  : () => _edit(),
              icon: const Icon(Icons.add),
              label: const Text('New announcement'),
            )
          : null,
      body: !auth.isLoggedIn
          ? const Center(
              child: Text('Please log in again to view announcements.'),
            )
          // holidays stay on top even when announcements fail or are empty
          : error != null
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: [
                const HolidaySection(),
                EmptyState(
                  icon: Icons.error_outline,
                  title: error,
                  buttonLabel: 'Retry',
                  onPressed: loading || _busy ? null : _load,
                ),
              ],
            )
          : loading
          ? const Center(child: CircularProgressIndicator())
          : announcements.isEmpty
          ? ListView(
              padding: const EdgeInsets.all(16),
              children: const [
                HolidaySection(),
                EmptyState(
                  icon: Icons.campaign_outlined,
                  title: 'No announcements yet',
                  message: 'Boarding house updates will appear here.',
                ),
              ],
            )
          : ListView.builder(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 100),
              // first item = holiday card, then the announcements
              itemCount: announcements.length + 1,
              itemBuilder: (context, index) {
                if (index == 0) {
                  return const Padding(
                    padding: EdgeInsets.only(bottom: 16),
                    child: HolidaySection(),
                  );
                }
                final announcement = announcements[index - 1];
                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          announcement.title,
                          style: const TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(announcement.message),
                        const SizedBox(height: 12),
                        if (announcement.eventDate != null)
                          Text('Event: ${_dateLabel(announcement.eventDate!)}'),
                        Text('Posted: ${_dateLabel(announcement.createdAt)}'),
                        if (auth.isOwner)
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              IconButton(
                                tooltip: 'Edit announcement',
                                onPressed: _busy || announcement.id == null
                                    ? null
                                    : () => _edit(announcement),
                                icon: const Icon(Icons.edit_outlined),
                              ),
                              IconButton(
                                tooltip: 'Remove announcement',
                                onPressed: _busy || announcement.id == null
                                    ? null
                                    : () => _remove(announcement),
                                icon: const Icon(Icons.delete_outline),
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

String _dateLabel(String value) {
  final date = DateTime.tryParse(value);
  if (date == null) return value;
  return '${date.year}-${date.month.toString().padLeft(2, '0')}-${date.day.toString().padLeft(2, '0')}';
}

class _AnnouncementDialog extends StatefulWidget {
  final Announcement? announcement;
  const _AnnouncementDialog({this.announcement});
  @override
  State<_AnnouncementDialog> createState() => _AnnouncementDialogState();
}

class _AnnouncementDialogState extends State<_AnnouncementDialog> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _messageController;
  late final TextEditingController _dateController;
  bool _saving = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.announcement?.title);
    _messageController = TextEditingController(
      text: widget.announcement?.message,
    );
    _dateController = TextEditingController(
      text: widget.announcement?.eventDate,
    );
  }

  @override
  void dispose() {
    _titleController.dispose();
    _messageController.dispose();
    _dateController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (_saving || !_formKey.currentState!.validate()) return;
    final auth = context.read<AuthProvider>();
    if (!auth.isLoggedIn || !auth.isOwner) {
      setState(() => _error = 'Please log in as the owner again.');
      return;
    }
    setState(() {
      _saving = true;
      _error = null;
    });
    final provider = context.read<AnnouncementProvider>();
    final original = widget.announcement;
    final announcement = Announcement(
      id: original?.id,
      title: _titleController.text.trim(),
      message: _messageController.text.trim(),
      eventDate: _dateController.text.trim().isEmpty
          ? null
          : _dateController.text.trim(),
      createdAt: original?.createdAt ?? DateTime.now().toIso8601String(),
    );
    try {
      if (original == null) {
        await provider.addAnnouncement(announcement);
      } else {
        await provider.updateAnnouncement(announcement);
      }
      if (!mounted) return;
      if (provider.errorMessage != null) {
        setState(() {
          _saving = false;
          _error = provider.errorMessage;
        });
        return;
      }
      setState(() => _saving = false);
      // Rebuild PopScope before closing the saved form.
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              original == null
                  ? 'Announcement posted.'
                  : 'Announcement updated.',
            ),
          ),
        );
        Navigator.pop(context);
      });
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _saving = false;
        _error = 'Could not save announcement. Please try again.';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: !_saving,
      child: AlertDialog(
        backgroundColor: Colors.white,
        title: Text(
          widget.announcement == null
              ? 'New announcement'
              : 'Edit announcement',
        ),
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
                  controller: _messageController,
                  enabled: !_saving,
                  decoration: const InputDecoration(labelText: 'Message'),
                  textCapitalization: TextCapitalization.sentences,
                  minLines: 3,
                  maxLines: 6,
                  validator: (value) => value == null || value.trim().isEmpty
                      ? 'Message is required'
                      : null,
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _dateController,
                  enabled: !_saving,
                  decoration: const InputDecoration(
                    labelText: 'Event date (optional)',
                    hintText: 'YYYY-MM-DD',
                  ),
                  keyboardType: TextInputType.datetime,
                  validator: (value) {
                    final text = value?.trim() ?? '';
                    if (text.isEmpty) return null;
                    final date = DateTime.tryParse(text);
                    if (!RegExp(r'^\d{4}-\d{2}-\d{2}$').hasMatch(text) ||
                        date == null ||
                        _dateLabel(date.toIso8601String()) != text) {
                      return 'Enter a valid date as YYYY-MM-DD';
                    }
                    return null;
                  },
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
            onPressed: _saving ? null : _save,
            child: Text(_saving ? 'Saving...' : 'Save'),
          ),
        ],
      ),
    );
  }
}
