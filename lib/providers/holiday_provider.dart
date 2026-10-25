import 'package:flutter/foundation.dart';

import '../models/holiday.dart';
import '../services/holiday_service.dart';

// PH public holidays from the Nager.Date API (News tab, due dates)
class HolidayProvider extends ChangeNotifier {
  final HolidayService _service;

  // the tests pass a fake service so they don't need internet
  HolidayProvider({HolidayService? service})
    : _service = service ?? HolidayService();

  List<Holiday> _holidays = [];
  bool _isLoading = false;
  String? _errorMessage;
  // true = no internet, showing the list saved last time
  bool _isOffline = false;

  List<Holiday> get holidays => _holidays;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isOffline => _isOffline;

  // from today on, for the News tab
  List<Holiday> get upcomingHolidays {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    return _holidays.where((h) => !h.date.isBefore(today)).toList();
  }

  // this year and next year, so a December due date can move into January
  Future<void> loadHolidays() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    final year = DateTime.now().year;
    try {
      final thisYear = await _service.fetchHolidays(year);
      final nextYear = await _service.fetchHolidays(year + 1);
      _holidays = [...thisYear, ...nextYear];
      _isOffline = false;
    } on HolidayException catch (e) {
      // API failed: use the saved list if we have one
      final saved = [
        ...await _service.getSavedHolidays(year),
        ...await _service.getSavedHolidays(year + 1),
      ];
      if (saved.isEmpty) {
        _holidays = [];
        _isOffline = false;
        _errorMessage = 'Could not load holidays. ${e.message}';
      } else {
        _holidays = saved;
        _isOffline = true;
      }
    }
    _isLoading = false;
    notifyListeners();
  }
}
