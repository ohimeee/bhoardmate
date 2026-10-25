import 'package:bhoardmate/models/holiday.dart';
import 'package:bhoardmate/services/holiday_service.dart';

// HolidayService without internet for widget tests.
// offline = true acts like no connection; saved = the list on the phone
class FakeHolidayService extends HolidayService {
  bool offline = false;
  List<Holiday> saved = [];
  // what the API returns; null = sample() for each year
  List<Holiday>? online;

  // a few holidays in the given year
  static List<Holiday> sample(int year) {
    return [
      Holiday(
        date: DateTime(year, 11, 30),
        localName: 'Araw ni Gat Andres Bonifacio',
        name: 'Bonifacio Day',
      ),
      Holiday(
        date: DateTime(year, 12, 25),
        localName: 'Araw ng Pasko',
        name: 'Christmas Day',
      ),
    ];
  }

  @override
  Future<List<Holiday>> fetchHolidays(int year) async {
    if (offline) throw const HolidayException('No internet connection.');
    if (online != null) {
      return online!.where((h) => h.date.year == year).toList();
    }
    return sample(year);
  }

  @override
  Future<List<Holiday>> getSavedHolidays(int year) async {
    return saved.where((h) => h.date.year == year).toList();
  }
}
