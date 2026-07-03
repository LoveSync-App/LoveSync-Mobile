import 'package:lovesync_mobile/features/calendar/domain/entities/calendar_event.dart';
import 'package:lovesync_mobile/features/calendar/domain/repositories/calendar_repository.dart';

class CreateCalendarEvent {
  const CreateCalendarEvent(this.repository);

  final CalendarRepository repository;

  Future<CalendarEvent> call(CalendarEventInput input) {
    return repository.createEvent(input);
  }
}
