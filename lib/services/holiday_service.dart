import 'dart:async';
import 'dart:convert';

import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../models/holiday.dart';

// thrown when the holidays can't be fetched, message is shown in the UI
class HolidayException implements Exception {
  final String message;

  const HolidayException(this.message);

  @override
  String toString() => message;
}

// Nager.Date API (PH public holidays). The only code that imports http
class HolidayService {
  final http.Client _client;

  // the tests pass a MockClient so they don't need internet
  HolidayService({http.Client? client}) : _client = client ?? http.Client();

  static const _baseUrl = 'https://date.nager.at/api/v3/PublicHolidays';

  // GET .../PublicHolidays/2026/PH -> list of Holiday.
  // a good answer is also saved on the phone for offline use
  Future<List<Holiday>> fetchHolidays(int year) async {
    final http.Response response;
    try {
      response = await _client
          .get(Uri.parse('$_baseUrl/$year/PH'))
          .timeout(const Duration(seconds: 10));
    } on TimeoutException {
      throw const HolidayException('No internet connection.');
    } on http.ClientException {
      // no connection, DNS failed, connection dropped
      throw const HolidayException('No internet connection.');
    }

    if (response.statusCode != 200) {
      throw HolidayException('Holiday server error (${response.statusCode}).');
    }

    final List<Holiday> holidays;
    try {
      holidays = _parse(response.body);
    } catch (e) {
      // not JSON, or a field is missing / the wrong type
      throw const HolidayException('Holiday server sent bad data.');
    }
    await _save(year, response.body);
    return holidays;
  }

  // last good answer for that year, empty if never fetched
  Future<List<Holiday>> getSavedHolidays(int year) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final body = prefs.getString('holidays_$year');
      if (body == null) return [];
      return _parse(body);
    } catch (e) {
      // the cache is only a backup, a broken one counts as empty
      return [];
    }
  }

  List<Holiday> _parse(String body) {
    final List<dynamic> data = jsonDecode(body);
    return data
        .map((item) => Holiday.fromJson(item as Map<String, dynamic>))
        .toList();
  }

  Future<void> _save(int year, String body) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('holidays_$year', body);
    } catch (e) {
      // saving failed: the list still shows, only offline mode misses it
    }
  }
}
