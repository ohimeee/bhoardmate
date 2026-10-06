import 'package:flutter/foundation.dart';

import '../models/holiday.dart';

// sample data for now, real API (HolidayService) comes in #14
class HolidayProvider extends ChangeNotifier {
  List<Holiday> _holidays = [];
  final bool _isLoading = false;
  String? _errorMessage;
  final bool _isOffline = false;

  List<Holiday> get holidays => _holidays;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isOffline => _isOffline;

  Future<void> loadHolidays() async {
    _holidays = [
      Holiday(
        date: DateTime(2026, 11, 1),
        localName: 'Araw ng mga Santo',
        name: "All Saints' Day",
      ),
      Holiday(
        date: DateTime(2026, 11, 30),
        localName: 'Araw ni Bonifacio',
        name: 'Bonifacio Day',
      ),
      Holiday(
        date: DateTime(2026, 12, 8),
        localName: 'Kapistahan ng Immaculada Concepcion',
        name: 'Feast of the Immaculate Conception',
      ),
      Holiday(
        date: DateTime(2026, 12, 25),
        localName: 'Araw ng Pasko',
        name: 'Christmas Day',
      ),
      Holiday(
        date: DateTime(2026, 12, 30),
        localName: 'Araw ni Rizal',
        name: 'Rizal Day',
      ),
    ];
    _errorMessage = null;
    notifyListeners();
  }
}
