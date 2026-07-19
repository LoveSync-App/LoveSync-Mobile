import 'package:lovesync_mobile/features/calendar/domain/repositories/calendar_repository.dart';

class DeleteCalendarEvent {
  const DeleteCalendarEvent(this.repository);

  final CalendarRepository repository;

  Future<void> call(String eventId) {
    return repository.deleteEvent(eventId);
  }
}
