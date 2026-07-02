import 'package:lovesync_mobile/features/calendar/domain/entities/calendar_event.dart';

class CalendarEventModel {
  const CalendarEventModel._();

  static CalendarEvent fromJson(Map<String, dynamic> json) {
    final startsAt = _readDate(json['startsAt']);
    final occurrenceAt = _readDate(json['occurrenceAt']) ?? startsAt;

    return CalendarEvent(
      id: (json['_id'] ?? json['id'] ?? '').toString(),
      type: _readType(json['type']),
      title: (json['title'] ?? '').toString(),
      description: (json['description'] ?? '').toString(),
      startsAt: startsAt ?? DateTime.now(),
      occurrenceAt: occurrenceAt ?? DateTime.now(),
      occurrenceKey: (json['occurrenceKey'] ?? json['_id'] ?? json['id'] ?? '')
          .toString(),
      location: json['location']?.toString(),
      recurrence: _readRecurrence(json['recurrence']),
      reminderEnabled: json['reminderEnabled'] != false,
      reminderMinutesBefore: _readInt(json['reminderMinutesBefore'], 1440),
      nextReminderAt: _readDate(json['nextReminderAt']),
    );
  }

  static List<CalendarEvent> listFromData(dynamic data) {
    dynamic source = data;
    for (var index = 0; index < 2 && source is Map; index++) {
      source = source['data'] ?? source['items'] ?? source['events'];
    }
    if (source is! List) return const [];

    return source
        .whereType<Map>()
        .map(
          (item) => fromJson(
            item.map((key, value) => MapEntry(key.toString(), value)),
          ),
        )
        .toList();
  }

  static CalendarEvent fromData(dynamic data) {
    dynamic source = data;
    for (var index = 0; index < 2 && source is Map; index++) {
      final nested = source['data'] ?? source['event'];
      if (nested is! Map) break;
      source = nested;
    }
    final json = source is Map
        ? source.map((key, value) => MapEntry(key.toString(), value))
        : <String, dynamic>{};
    return fromJson(json);
  }

  static CalendarEventType _readType(dynamic value) {
    return value?.toString().toUpperCase() == 'IMPORTANT_DATE'
        ? CalendarEventType.importantDate
        : CalendarEventType.appointment;
  }

  static CalendarRecurrence _readRecurrence(dynamic value) {
    return value?.toString().toUpperCase() == 'YEARLY'
        ? CalendarRecurrence.yearly
        : CalendarRecurrence.none;
  }

  static DateTime? _readDate(dynamic value) {
    if (value is DateTime) return value.toLocal();
    if (value is String) return DateTime.tryParse(value)?.toLocal();
    return null;
  }

  static int _readInt(dynamic value, int fallback) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? fallback;
  }
}
