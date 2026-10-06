import 'package:flutter/foundation.dart';

import '../models/concern.dart';

// sample data for now, DatabaseService comes in #3
class ConcernProvider extends ChangeNotifier {
  final List<Concern> _all = [
    const Concern(
      id: 1,
      roomId: 'BH01-RM2',
      title: 'Leaking faucet',
      description: 'The bathroom faucet keeps dripping even when closed.',
      createdAt: '2026-10-04T08:20:00.000',
    ),
    const Concern(
      id: 2,
      roomId: 'BH01-RM1',
      title: 'Broken hallway light',
      description: 'The light near the stairs does not turn on anymore.',
      status: 'done',
      createdAt: '2026-10-01T19:45:00.000',
    ),
    const Concern(
      id: 3,
      roomId: 'BH01-RM3',
      title: 'Clogged sink',
      description: 'Water drains very slowly in the kitchen sink.',
      createdAt: '2026-10-06T07:10:00.000',
    ),
  ];

  String? _roomId;
  List<Concern> _concerns = [];
  final bool _isLoading = false;
  String? _errorMessage;

  List<Concern> get concerns => _concerns;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  int _nextId() {
    int max = 0;
    for (final c in _all) {
      if (c.id != null && c.id! > max) max = c.id!;
    }
    return max + 1;
  }

  void _refresh() {
    _concerns = _all
        .where((c) => _roomId == null || c.roomId == _roomId)
        .toList();
    notifyListeners();
  }

  Future<void> loadConcerns({String? roomId}) async {
    _roomId = roomId;
    _errorMessage = null;
    _refresh();
  }

  Future<void> addConcern(Concern concern) async {
    _all.add(concern.copyWith(id: _nextId()));
    _refresh();
  }

  Future<void> toggleStatus(int id) async {
    final index = _all.indexWhere((c) => c.id == id);
    if (index == -1) return;
    final c = _all[index];
    _all[index] = c.copyWith(
      status: c.status == 'pending' ? 'done' : 'pending',
    );
    _refresh();
  }

  Future<void> deleteConcern(int id) async {
    _all.removeWhere((c) => c.id == id);
    _refresh();
  }
}
