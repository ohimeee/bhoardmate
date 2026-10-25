import 'package:bhoardmate/models/holiday.dart';
import 'package:bhoardmate/providers/holiday_provider.dart';
import 'package:flutter_test/flutter_test.dart';

import 'fake_holiday_service.dart';

void main() {
  final year = DateTime.now().year;

  test('loads this year and next year from the API', () async {
    final provider = HolidayProvider(service: FakeHolidayService());
    await provider.loadHolidays();
    expect(provider.holidays.length, 4);
    expect(provider.holidays.last.date, DateTime(year + 1, 12, 25));
    expect(provider.isLoading, isFalse);
    expect(provider.isOffline, isFalse);
    expect(provider.errorMessage, isNull);
    // next year's are always upcoming
    expect(
      provider.upcomingHolidays.where((h) => h.date.year == year + 1).length,
      2,
    );
  });

  test('offline with a saved list shows the saved holidays', () async {
    final service = FakeHolidayService()
      ..offline = true
      ..saved = FakeHolidayService.sample(year);
    final provider = HolidayProvider(service: service);
    await provider.loadHolidays();
    expect(provider.holidays.length, 2);
    expect(provider.isOffline, isTrue);
    expect(provider.errorMessage, isNull);
  });

  test('offline with nothing saved shows an error, retry works', () async {
    final service = FakeHolidayService()..offline = true;
    final provider = HolidayProvider(service: service);
    await provider.loadHolidays();
    expect(provider.holidays, isEmpty);
    expect(
      provider.errorMessage,
      'Could not load holidays. No internet connection.',
    );

    service.offline = false;
    await provider.loadHolidays();
    expect(provider.errorMessage, isNull);
    expect(provider.holidays.length, 4);
  });

  test('past holidays are not upcoming', () async {
    final service = FakeHolidayService()
      ..offline = true
      ..saved = [
        Holiday(
          date: DateTime(year, 1, 1),
          localName: 'Bagong Taon',
          name: "New Year's Day",
        ),
        ...FakeHolidayService.sample(year + 1),
      ];
    final provider = HolidayProvider(service: service);
    await provider.loadHolidays();
    expect(provider.holidays.length, 3);
    expect(provider.upcomingHolidays.length, 2);
  });

  // first day in that month with the given weekday (DateTime.monday ...)
  DateTime firstWeekday(int year, int month, int weekday) {
    var day = DateTime(year, month, 1);
    while (day.weekday != weekday) {
      day = DateTime(year, month, day.day + 1);
    }
    return day;
  }

  test(
    'due date rule: weekends and holidays move to the next working day',
    () async {
      // next year so the dates are always loaded (this year + next year)
      final next = year + 1;
      final mondayHoliday = firstWeekday(next, 6, DateTime.monday);
      final fridayHoliday = firstWeekday(next, 8, DateTime.friday);
      final service = FakeHolidayService()
        ..offline = true
        ..saved = [
          Holiday(
            date: mondayHoliday,
            localName: 'Pista',
            name: 'Test Holiday',
          ),
          Holiday(
            date: fridayHoliday,
            localName: 'Pista',
            name: 'Long Weekend',
          ),
        ];
      final provider = HolidayProvider(service: service);
      await provider.loadHolidays();

      // working day stays
      final wednesday = firstWeekday(next, 3, DateTime.wednesday);
      expect(provider.nextWorkingDay(wednesday), wednesday);
      expect(provider.dayOffReason(wednesday), isNull);

      // Saturday -> Monday
      final saturday = firstWeekday(next, 3, DateTime.saturday);
      expect(
        provider.nextWorkingDay(saturday),
        saturday.add(const Duration(days: 2)),
      );
      expect(provider.dayOffReason(saturday), 'Saturday');

      // holiday on a Monday -> Tuesday
      expect(
        provider.nextWorkingDay(mondayHoliday),
        DateTime(next, 6, mondayHoliday.day + 1),
      );
      expect(provider.dayOffReason(mondayHoliday), 'Test Holiday');

      // Friday holiday -> skips Sat and Sun -> Monday
      expect(
        provider.nextWorkingDay(fridayHoliday),
        DateTime(next, 8, fridayHoliday.day + 3),
      );

      // string version used by the screens
      final text = fridayHoliday.toIso8601String().substring(0, 10);
      final moved = DateTime(next, 8, fridayHoliday.day + 3);
      expect(provider.dueDate(text), moved.toIso8601String().substring(0, 10));
      expect(provider.dueDateNote(text), 'Moved from $text (Long Weekend)');
      final working = wednesday.toIso8601String().substring(0, 10);
      expect(provider.dueDate(working), working);
      expect(provider.dueDateNote(working), isNull);
    },
  );

  test('weekend rule still works with no holidays loaded', () async {
    final provider = HolidayProvider(
      service: FakeHolidayService()..offline = true,
    );
    await provider.loadHolidays();
    expect(provider.holidays, isEmpty);
    // 2026-10-10 is a Saturday
    expect(provider.dueDate('2026-10-10'), '2026-10-12');
    expect(
      provider.dueDateNote('2026-10-10'),
      'Moved from 2026-10-10 (Saturday)',
    );
  });
}
