import 'package:lovesync_mobile/features/calendar/domain/entities/calendar_event.dart';
import 'package:lovesync_mobile/features/calendar/domain/repositories/calendar_repository.dart';

class UpdateCalendarEvent {
  const UpdateCalendarEvent(this.repository);

  final CalendarRepository repository;

  Future<CalendarEvent> call(String eventId, CalendarEventInput input) {
    return repository.updateEvent(eventId, input);
  }
}
