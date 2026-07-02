enum CalendarEventType { appointment, importantDate }

enum CalendarRecurrence { none, yearly }

class CalendarEvent {
  const CalendarEvent({
    required this.id,
    required this.type,
    required this.title,
    required this.startsAt,
    required this.occurrenceAt,
    required this.occurrenceKey,
    required this.recurrence,
    required this.reminderEnabled,
    required this.reminderMinutesBefore,
    this.description = '',
    this.location,
    this.nextReminderAt,
  });

  final String id;
  final CalendarEventType type;
  final String title;
  final String description;
  final DateTime startsAt;
  final DateTime occurrenceAt;
  final String occurrenceKey;
  final String? location;
  final CalendarRecurrence recurrence;
  final bool reminderEnabled;
  final int reminderMinutesBefore;
  final DateTime? nextReminderAt;
}
