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

  // the holiday on that day, null if there is none
  Holiday? holidayOn(DateTime day) {
    for (final h in _holidays) {
      if (h.date.year == day.year &&
          h.date.month == day.month &&
          h.date.day == day.day) {
        return h;
      }
    }
    return null;
  }

  // why that day is not a working day: holiday name, Saturday,
  // Sunday, or null if it is a working day
  String? dayOffReason(DateTime day) {
    final holiday = holidayOn(day);
    if (holiday != null) return holiday.name;
    if (day.weekday == DateTime.saturday) return 'Saturday';
    if (day.weekday == DateTime.sunday) return 'Sunday';
    return null;
  }

  // due date rule: a holiday or weekend moves to the next working day
  // (e.g. Fri holiday -> skips Sat and Sun -> Monday)
  DateTime nextWorkingDay(DateTime date) {
    var day = DateTime(date.year, date.month, date.day);
    while (dayOffReason(day) != null) {
      day = DateTime(day.year, day.month, day.day + 1);
    }
    return day;
  }

  // same rule for the 'yyyy-MM-dd' strings saved in the bills.
  // the bill keeps the owner's date, the app shows the moved one
  String dueDate(String date) {
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return date;
    return nextWorkingDay(parsed).toIso8601String().substring(0, 10);
  }

  // 'Moved from 2026-11-30 (Bonifacio Day)', null if the date didn't move
  String? dueDateNote(String date) {
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return null;
    final reason = dayOffReason(parsed);
    if (reason == null) return null;
    return 'Moved from $date ($reason)';
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
