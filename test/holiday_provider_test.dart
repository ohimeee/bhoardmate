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
}
