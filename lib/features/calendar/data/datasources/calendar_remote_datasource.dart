import 'package:dio/dio.dart';
import 'package:lovesync_mobile/features/calendar/data/models/calendar_event_model.dart';
import 'package:lovesync_mobile/features/calendar/domain/entities/calendar_event.dart';

class CalendarRemoteDatasource {
  const CalendarRemoteDatasource(this.dio);

  final Dio dio;

  Future<List<CalendarEvent>> getEvents({
    required DateTime from,
    required DateTime to,
    CalendarEventType? type,
  }) async {
    final response = await dio.get(
      '/calendar/events',
      queryParameters: {
        'from': from.toUtc().toIso8601String(),
        'to': to.toUtc().toIso8601String(),
        if (type != null) 'type': _typeValue(type),
      },
    );
    return CalendarEventModel.listFromData(response.data);
  }

  Future<CalendarEvent> getEvent(String eventId) async {
    final response = await dio.get('/calendar/events/$eventId');
    return CalendarEventModel.fromData(response.data);
  }

  Future<CalendarEvent> createEvent(Map<String, dynamic> data) async {
    final response = await dio.post('/calendar/events', data: data);
    return CalendarEventModel.fromData(response.data);
  }

  Future<CalendarEvent> updateEvent(
    String eventId,
    Map<String, dynamic> data,
  ) async {
    final response = await dio.patch('/calendar/events/$eventId', data: data);
    return CalendarEventModel.fromData(response.data);
  }

  Future<void> deleteEvent(String eventId) async {
    await dio.delete('/calendar/events/$eventId');
  }

  static String typeValue(CalendarEventType type) => _typeValue(type);

  static String recurrenceValue(CalendarRecurrence recurrence) {
    return recurrence == CalendarRecurrence.yearly ? 'YEARLY' : 'NONE';
  }

  static String _typeValue(CalendarEventType type) {
    return type == CalendarEventType.importantDate
        ? 'IMPORTANT_DATE'
        : 'APPOINTMENT';
  }
}
