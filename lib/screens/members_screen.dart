import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/auth_provider.dart';
import 'member_detail_screen.dart';
import 'owner_profile_screen.dart';

class MembersScreen extends StatefulWidget {
  final bool showOwnProfile;
  const MembersScreen({super.key, this.showOwnProfile = false});
  @override
  State<MembersScreen> createState() => _MembersScreenState();
}

class _MembersScreenState extends State<MembersScreen> {
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
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      await context.read<AuthProvider>().loadRooms();
      if (!mounted) return;
      setState(() => _error = context.read<AuthProvider>().errorMessage);
    } catch (_) {
      if (!mounted) return;
      setState(() => _error = 'Could not load members. Please try again.');
    }
    if (!mounted) return;
    setState(() => _loading = false);
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();
    if (widget.showOwnProfile && auth.isLoggedIn && auth.isOwner) {
      return OwnerProfileScreen(onSave: auth.updateOwner);
    }
    if (widget.showOwnProfile && auth.isLoggedIn && !auth.isOwner) {
      final ownRooms = auth.rooms.where(
        (room) => room.id == auth.currentRoomId,
      );
      if (ownRooms.isNotEmpty && !_loading && _error == null) {
        return MemberDetailScreen(room: ownRooms.first);
      }
    }
    final rooms = auth.rooms
        .where(
          (room) =>
              auth.isOwner ||
              room.id == auth.currentRoomId ||
              room.boarderName?.trim().isNotEmpty == true,
        )
        .toList();
    return Scaffold(
      backgroundColor: const Color(0xFFFAF6EE),
      appBar: AppBar(
        title: const Text('Members'),
        backgroundColor: const Color(0xFFFDE7D3),
      ),
      body: !auth.isLoggedIn
          ? const Center(child: Text('Please log in to view members.'))
          : _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!),
                  TextButton(onPressed: _load, child: const Text('Retry')),
                ],
              ),
            )
          : rooms.isEmpty
          ? const Center(child: Text('No members yet'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: rooms.length,
              itemBuilder: (context, index) {
                final room = rooms[index];
                return Card(
                  color: Colors.white,
                  elevation: 3,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: ListTile(
                    title: Text(
                      room.id == auth.currentRoomId
                          ? '${room.id} (You)'
                          : room.id,
                    ),
                    subtitle: Text(
                      room.boarderName?.trim().isNotEmpty == true
                          ? room.boarderName!
                          : 'Vacant room',
                    ),
                    trailing: const Icon(Icons.chevron_right),
                    onTap: () => Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (context) => MemberDetailScreen(room: room),
                      ),
                    ),
                  ),
                );
              },
            ),
    );
  }
}
