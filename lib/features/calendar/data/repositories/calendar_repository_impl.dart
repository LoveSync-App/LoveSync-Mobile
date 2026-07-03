import 'package:dio/dio.dart';
import 'package:lovesync_mobile/features/calendar/data/datasources/calendar_remote_datasource.dart';
import 'package:lovesync_mobile/features/calendar/domain/entities/calendar_event.dart';
import 'package:lovesync_mobile/features/calendar/domain/repositories/calendar_repository.dart';

class CalendarRepositoryImpl implements CalendarRepository {
  const CalendarRepositoryImpl(this.remoteDatasource);

  CalendarRepositoryImpl.fromDio(Dio dio)
    : remoteDatasource = CalendarRemoteDatasource(dio);

  final CalendarRemoteDatasource remoteDatasource;

  @override
  Future<CalendarEvent> createEvent(CalendarEventInput input) {
    return remoteDatasource.createEvent(_toJson(input));
  }

  @override
  Future<void> deleteEvent(String eventId) {
    return remoteDatasource.deleteEvent(eventId);
  }

  @override
  Future<CalendarEvent> getEvent(String eventId) {
    return remoteDatasource.getEvent(eventId);
  }

  @override
  Future<List<CalendarEvent>> getEvents({
    required DateTime from,
    required DateTime to,
    CalendarEventType? type,
  }) {
    return remoteDatasource.getEvents(from: from, to: to, type: type);
  }

  @override
  Future<CalendarEvent> updateEvent(String eventId, CalendarEventInput input) {
    return remoteDatasource.updateEvent(eventId, _toJson(input));
  }

  Map<String, dynamic> _toJson(CalendarEventInput input) {
    final recurrence = input.type == CalendarEventType.appointment
        ? CalendarRecurrence.none
        : input.recurrence;
    return {
      'type': _typeValue(input.type),
      'title': input.title,
      'description': input.description,
      'startsAt': input.startsAt.toUtc().toIso8601String(),
      if (input.type == CalendarEventType.appointment && input.location != null)
        'location': input.location,
      'recurrence': _recurrenceValue(recurrence),
      'reminderEnabled': input.reminderEnabled,
      'reminderMinutesBefore': input.reminderMinutesBefore,
    };
  }

  String _typeValue(CalendarEventType type) {
    return type == CalendarEventType.importantDate
        ? 'IMPORTANT_DATE'
        : 'APPOINTMENT';
  }

  String _recurrenceValue(CalendarRecurrence recurrence) {
    return recurrence == CalendarRecurrence.yearly ? 'YEARLY' : 'NONE';
  }
}
