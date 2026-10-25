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
  // years we really have holidays for (API or saved list)
  Set<int> _years = {};

  List<Holiday> get holidays => _holidays;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isOffline => _isOffline;

  bool hasHolidaysFor(int year) => _years.contains(year);

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

  // 'Moved from 2026-11-30 (Bonifacio Day)', null if the date didn't move.
  // also says so when the holidays of that year are missing, so a
  // weekday holiday never stays on the bill without a warning
  String? dueDateNote(String date) {
    final parsed = DateTime.tryParse(date);
    if (parsed == null) return null;
    final reason = dayOffReason(parsed);
    final moved = nextWorkingDay(parsed);
    final missing = !hasHolidaysFor(parsed.year) || !hasHolidaysFor(moved.year);
    if (missing) {
      final check = _isLoading
          ? 'checking holidays...'
          : 'holidays not loaded, only weekends checked';
      return reason == null ? check : 'Moved from $date ($reason), $check';
    }
    if (reason == null) return null;
    return 'Moved from $date ($reason)';
  }

  // last year (unpaid old bills), this year and next year (a December
  // due date can move into January). Each year on its own: if one fails
  // we still use the others, and remember which years we really have
  Future<void> loadHolidays() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();
    final now = DateTime.now().year;
    final list = <Holiday>[];
    final years = <int>{};
    bool usedSaved = false;
    String? lastError;
    for (final year in [now - 1, now, now + 1]) {
      try {
        list.addAll(await _service.fetchHolidays(year));
        years.add(year);
      } on HolidayException catch (e) {
        // API failed: use the saved list for that year if we have one
        final saved = await _service.getSavedHolidays(year);
        if (saved.isNotEmpty) {
          list.addAll(saved);
          years.add(year);
          usedSaved = true;
        }
        lastError = e.message;
      }
    }
    _holidays = list;
    _years = years;
    _isOffline = usedSaved;
    if (years.isEmpty && lastError != null) {
      _errorMessage = 'Could not load holidays. $lastError';
    }
    _isLoading = false;
    notifyListeners();
  }
}
