import 'package:lovesync_mobile/features/calendar/domain/entities/calendar_event.dart';
import 'package:lovesync_mobile/features/calendar/domain/repositories/calendar_repository.dart';

class GetCalendarEvents {
  const GetCalendarEvents(this.repository);

  final CalendarRepository repository;

  Future<List<CalendarEvent>> call({
    required DateTime from,
    required DateTime to,
    CalendarEventType? type,
  }) {
    return repository.getEvents(from: from, to: to, type: type);
  }
}
