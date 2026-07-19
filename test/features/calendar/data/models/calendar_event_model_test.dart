import 'package:flutter_test/flutter_test.dart';
import 'package:lovesync_mobile/features/calendar/data/models/calendar_event_model.dart';
import 'package:lovesync_mobile/features/calendar/domain/entities/calendar_event.dart';

void main() {
  test('uses occurrenceAt for a yearly important date', () {
    final event = CalendarEventModel.fromJson({
      '_id': 'event-id',
      'type': 'IMPORTANT_DATE',
      'title': 'Ngày kỷ niệm',
      'startsAt': '2024-07-10T00:00:00.000Z',
      'occurrenceAt': '2026-07-10T00:00:00.000Z',
      'occurrenceKey': 'event-id:2026-07-10T00:00:00.000Z',
      'recurrence': 'YEARLY',
      'reminderEnabled': true,
      'reminderMinutesBefore': 1440,
    });

    expect(event.id, 'event-id');
    expect(event.type, CalendarEventType.importantDate);
    expect(event.recurrence, CalendarRecurrence.yearly);
    expect(event.startsAt.year, 2024);
    expect(event.occurrenceAt.year, 2026);
    expect(event.occurrenceKey, contains('2026-07-10'));
  });

  test('parses direct array calendar response in order', () {
    final events = CalendarEventModel.listFromData([
      {
        '_id': 'first',
        'type': 'APPOINTMENT',
        'title': 'Ăn tối',
        'startsAt': '2026-07-10T12:00:00.000Z',
        'occurrenceAt': '2026-07-10T12:00:00.000Z',
        'recurrence': 'NONE',
      },
      {
        '_id': 'second',
        'type': 'IMPORTANT_DATE',
        'title': 'Kỷ niệm',
        'startsAt': '2026-07-20T00:00:00.000Z',
        'occurrenceAt': '2026-07-20T00:00:00.000Z',
        'recurrence': 'YEARLY',
      },
    ]);

    expect(events.map((event) => event.id), ['first', 'second']);
  });
}
