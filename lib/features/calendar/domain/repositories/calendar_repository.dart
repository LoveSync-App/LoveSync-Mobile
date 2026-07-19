import 'package:lovesync_mobile/features/calendar/domain/entities/calendar_event.dart';

abstract class CalendarRepository {
  Future<List<CalendarEvent>> getEvents({
    required DateTime from,
    required DateTime to,
    CalendarEventType? type,
  });

  Future<CalendarEvent> getEvent(String eventId);

  Future<CalendarEvent> createEvent(CalendarEventInput input);

  Future<CalendarEvent> updateEvent(String eventId, CalendarEventInput input);

  Future<void> deleteEvent(String eventId);
}
