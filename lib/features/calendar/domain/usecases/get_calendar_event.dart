import 'package:lovesync_mobile/features/calendar/domain/entities/calendar_event.dart';
import 'package:lovesync_mobile/features/calendar/domain/repositories/calendar_repository.dart';

class GetCalendarEvent {
  const GetCalendarEvent(this.repository);

  final CalendarRepository repository;

  Future<CalendarEvent> call(String eventId) {
    return repository.getEvent(eventId);
  }
}
