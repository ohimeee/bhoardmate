import 'dart:convert';

import 'package:bhoardmate/services/holiday_service.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:shared_preferences/shared_preferences.dart';

// part of the real Nager.Date answer for 2026
final sampleJson = jsonEncode([
  {
    'date': '2026-11-30',
    'localName': 'Araw ni Gat Andres Bonifacio',
    'name': 'Bonifacio Day',
    'countryCode': 'PH',
    'fixed': true,
    'global': true,
    'types': ['Public'],
  },
  {
    'date': '2026-12-25',
    'localName': 'Araw ng Pasko',
    'name': 'Christmas Day',
    'countryCode': 'PH',
    'fixed': true,
    'global': true,
    'types': ['Public'],
  },
]);

void main() {
  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  test('parses the JSON into Holiday objects and saves it', () async {
    Uri? calledUrl;
    final service = HolidayService(
      client: MockClient((request) async {
        calledUrl = request.url;
        return http.Response(sampleJson, 200);
      }),
    );
    final holidays = await service.fetchHolidays(2026);
    expect(
      calledUrl.toString(),
      'https://date.nager.at/api/v3/PublicHolidays/2026/PH',
    );
    expect(holidays.length, 2);
    expect(holidays[1].name, 'Christmas Day');
    expect(holidays[1].localName, 'Araw ng Pasko');
    expect(holidays[1].date, DateTime(2026, 12, 25));

    // saved for offline use
    final saved = await service.getSavedHolidays(2026);
    expect(saved.length, 2);
    expect(await service.getSavedHolidays(2027), isEmpty);
  });

  test(
    'no internet, server error and bad data throw HolidayException',
    () async {
      final offline = HolidayService(
        client: MockClient((request) async {
          throw http.ClientException('Failed host lookup');
        }),
      );
      expect(
        () => offline.fetchHolidays(2026),
        throwsA(
          isA<HolidayException>().having(
            (e) => e.message,
            'message',
            'No internet connection.',
          ),
        ),
      );

      final notFound = HolidayService(
        client: MockClient((request) async => http.Response('', 404)),
      );
      expect(
        () => notFound.fetchHolidays(2026),
        throwsA(
          isA<HolidayException>().having(
            (e) => e.message,
            'message',
            'Holiday server error (404).',
          ),
        ),
      );

      final badData = HolidayService(
        client: MockClient(
          (request) async => http.Response('{"oops": true}', 200),
        ),
      );
      expect(
        () => badData.fetchHolidays(2026),
        throwsA(isA<HolidayException>()),
      );
    },
  );
}
