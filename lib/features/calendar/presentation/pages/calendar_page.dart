import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lovesync_mobile/core/network/dio_client.dart';
import 'package:lovesync_mobile/features/calendar/data/datasources/calendar_remote_datasource.dart';
import 'package:lovesync_mobile/features/calendar/domain/entities/calendar_event.dart';
import 'package:lovesync_mobile/features/calendar/presentation/pages/calendar_event_form_page.dart';
import 'package:provider/provider.dart';

class CalendarPage extends StatefulWidget {
  const CalendarPage({super.key});

  @override
  State<CalendarPage> createState() => _CalendarPageState();
}

class _CalendarPageState extends State<CalendarPage> {
  late final CalendarRemoteDatasource _datasource;
  final List<CalendarEvent> _events = [];

  late DateTime _visibleMonth;
  late DateTime _selectedDate;
  bool _isLoading = true;
  bool _isFetching = false;
  bool _hasLoadedOnce = false;
  bool _wasVisible = false;
  String? _openingEventId;

  @override
  void initState() {
    super.initState();
    final today = DateTime.now();
    _visibleMonth = DateTime(today.year, today.month);
    _selectedDate = DateTime(today.year, today.month, today.day);
    _datasource = CalendarRemoteDatasource(context.read<DioClient>().dio);
    _loadMonth();
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final isVisible = TickerMode.of(context);
    if (isVisible && !_wasVisible && _hasLoadedOnce) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) _loadMonth(showLoading: false);
      });
    }
    _wasVisible = isVisible;
  }

  Future<void> _loadMonth({bool showLoading = true}) async {
    if (_isFetching) return;
    _isFetching = true;
    if (showLoading && mounted) setState(() => _isLoading = true);

    final from = DateTime(_visibleMonth.year, _visibleMonth.month);
    final to = DateTime(
      _visibleMonth.year,
      _visibleMonth.month + 1,
    ).subtract(const Duration(milliseconds: 1));

    try {
      final events = await _datasource.getEvents(from: from, to: to);
      events.sort((first, second) {
        return first.occurrenceAt.compareTo(second.occurrenceAt);
      });
      if (!mounted) return;
      setState(() {
        _events
          ..clear()
          ..addAll(events);
      });
    } on DioException catch (error) {
      if (mounted) _showError(_errorMessage(error, 'Không tải được lịch.'));
    } finally {
      _isFetching = false;
      _hasLoadedOnce = true;
      if (mounted) setState(() => _isLoading = false);
    }
  }

  void _changeMonth(int offset) {
    final next = DateTime(_visibleMonth.year, _visibleMonth.month + offset);
    setState(() {
      _visibleMonth = next;
      _selectedDate = DateTime(next.year, next.month, 1);
    });
    _loadMonth();
  }

  void _goToToday() {
    final today = DateTime.now();
    final changedMonth =
        today.year != _visibleMonth.year || today.month != _visibleMonth.month;
    setState(() {
      _visibleMonth = DateTime(today.year, today.month);
      _selectedDate = DateTime(today.year, today.month, today.day);
    });
    if (changedMonth) _loadMonth();
  }

  Future<void> _openCreateEvent() async {
    final now = DateTime.now();
    final initialDate = _sameDate(_selectedDate, now)
        ? now.add(const Duration(hours: 1))
        : DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            18,
          );
    final created = await _showEventForm(initialDate: initialDate);
    if (created == true && mounted) {
      await _loadMonth(showLoading: false);
    }
  }

  Future<void> _openEvent(CalendarEvent summary) async {
    if (_openingEventId != null) return;
    setState(() => _openingEventId = summary.id);

    CalendarEvent event = summary;
    try {
      final detail = await _datasource.getEvent(summary.id);
      event = CalendarEvent(
        id: detail.id,
        type: detail.type,
        title: detail.title,
        description: detail.description,
        startsAt: detail.startsAt,
        occurrenceAt: summary.occurrenceAt,
        occurrenceKey: summary.occurrenceKey,
        location: detail.location,
        recurrence: detail.recurrence,
        reminderEnabled: detail.reminderEnabled,
        reminderMinutesBefore: detail.reminderMinutesBefore,
        nextReminderAt: detail.nextReminderAt,
      );
    } on DioException {
      // The list response still contains enough data to edit the event.
    } finally {
      if (mounted) setState(() => _openingEventId = null);
    }
    if (!mounted) return;

    final changed = await _showEventForm(event: event);
    if (changed == true && mounted) {
      await _loadMonth(showLoading: false);
    }
  }

  Future<bool?> _showEventForm({CalendarEvent? event, DateTime? initialDate}) {
    return showModalBottomSheet<bool>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      showDragHandle: true,
      backgroundColor: const Color(0xFFFFF8FA),
      barrierColor: Colors.black.withValues(alpha: 0.42),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      clipBehavior: Clip.antiAlias,
      builder: (sheetContext) => SizedBox(
        height: MediaQuery.sizeOf(sheetContext).height * 0.88,
        child: CalendarEventFormPage(
          datasource: _datasource,
          event: event,
          initialDate: initialDate,
        ),
      ),
    );
  }

  List<CalendarEvent> _eventsOn(DateTime date) {
    return _events.where((event) {
      final occurrence = event.occurrenceAt;
      return occurrence.year == date.year &&
          occurrence.month == date.month &&
          occurrence.day == date.day;
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final selectedEvents = _eventsOn(_selectedDate);

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8FA),
      body: RefreshIndicator(
        onRefresh: () => _loadMonth(showLoading: false),
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 100),
          children: [
            _CalendarHeader(
              visibleMonth: _visibleMonth,
              onPrevious: () => _changeMonth(-1),
              onNext: () => _changeMonth(1),
              onToday: _goToToday,
            ),
            const SizedBox(height: 12),
            _MonthCalendar(
              visibleMonth: _visibleMonth,
              selectedDate: _selectedDate,
              events: _events,
              isLoading: _isLoading,
              onSelected: (date) => setState(() => _selectedDate = date),
            ),
            const SizedBox(height: 24),
            Row(
              children: [
                Expanded(
                  child: Text(
                    _selectedDateLabel(_selectedDate),
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ),
                Text(
                  '${selectedEvents.length} sự kiện',
                  style: const TextStyle(color: Color(0xFF81777B)),
                ),
              ],
            ),
            const SizedBox(height: 12),
            if (_isLoading)
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 32),
                child: Center(child: CircularProgressIndicator()),
              )
            else if (selectedEvents.isEmpty)
              const _EmptyDateCard()
            else
              ...selectedEvents.map(
                (event) => Padding(
                  key: ValueKey(event.occurrenceKey),
                  padding: const EdgeInsets.only(bottom: 10),
                  child: _EventCard(
                    event: event,
                    isOpening: _openingEventId == event.id,
                    onTap: () => _openEvent(event),
                  ),
                ),
              ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _openCreateEvent,
        backgroundColor: const Color(0xFFA03B56),
        foregroundColor: Colors.white,
        icon: const Icon(Icons.add_rounded),
        label: const Text('Thêm sự kiện'),
      ),
    );
  }

  String _selectedDateLabel(DateTime date) {
    final today = DateTime.now();
    if (_sameDate(date, today)) return 'Hôm nay';
    return DateFormat("EEEE, dd 'tháng' MM", 'vi_VN').format(date);
  }

  bool _sameDate(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }

  String _errorMessage(DioException error, String fallback) {
    final data = error.response?.data;
    if (data is Map) {
      final message = data['message'] ?? data['error'];
      if (message != null) return message.toString();
    }
    return fallback;
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

class _CalendarHeader extends StatelessWidget {
  const _CalendarHeader({
    required this.visibleMonth,
    required this.onPrevious,
    required this.onNext,
    required this.onToday,
  });

  final DateTime visibleMonth;
  final VoidCallback onPrevious;
  final VoidCallback onNext;
  final VoidCallback onToday;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Tháng ${visibleMonth.month}',
                style: const TextStyle(
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF2A2225),
                ),
              ),
              Text(
                visibleMonth.year.toString(),
                style: const TextStyle(color: Color(0xFF81777B)),
              ),
            ],
          ),
        ),
        TextButton(onPressed: onToday, child: const Text('Hôm nay')),
        IconButton.filledTonal(
          onPressed: onPrevious,
          icon: const Icon(Icons.chevron_left_rounded),
          tooltip: 'Tháng trước',
        ),
        const SizedBox(width: 6),
        IconButton.filledTonal(
          onPressed: onNext,
          icon: const Icon(Icons.chevron_right_rounded),
          tooltip: 'Tháng sau',
        ),
      ],
    );
  }
}

class _MonthCalendar extends StatelessWidget {
  const _MonthCalendar({
    required this.visibleMonth,
    required this.selectedDate,
    required this.events,
    required this.isLoading,
    required this.onSelected,
  });

  static const weekdays = ['T2', 'T3', 'T4', 'T5', 'T6', 'T7', 'CN'];

  final DateTime visibleMonth;
  final DateTime selectedDate;
  final List<CalendarEvent> events;
  final bool isLoading;
  final ValueChanged<DateTime> onSelected;

  @override
  Widget build(BuildContext context) {
    final firstDay = DateTime(visibleMonth.year, visibleMonth.month);
    final daysInMonth = DateTime(
      visibleMonth.year,
      visibleMonth.month + 1,
      0,
    ).day;
    final leadingEmptyCells = firstDay.weekday - 1;
    final cellCount = ((leadingEmptyCells + daysInMonth + 6) ~/ 7) * 7;

    return Container(
      padding: const EdgeInsets.fromLTRB(10, 16, 10, 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.055),
            blurRadius: 18,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        children: [
          Row(
            children: weekdays
                .map(
                  (weekday) => Expanded(
                    child: Center(
                      child: Text(
                        weekday,
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF91868B),
                        ),
                      ),
                    ),
                  ),
                )
                .toList(),
          ),
          const SizedBox(height: 8),
          if (isLoading)
            const SizedBox(
              height: 260,
              child: Center(child: CircularProgressIndicator()),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: cellCount,
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 7,
                childAspectRatio: 0.88,
              ),
              itemBuilder: (context, index) {
                final day = index - leadingEmptyCells + 1;
                if (day < 1 || day > daysInMonth) {
                  return const SizedBox.shrink();
                }
                final date = DateTime(
                  visibleMonth.year,
                  visibleMonth.month,
                  day,
                );
                return _CalendarDay(
                  date: date,
                  selected: _sameDate(date, selectedDate),
                  today: _sameDate(date, DateTime.now()),
                  events: _eventsOn(date),
                  onTap: () => onSelected(date),
                );
              },
            ),
        ],
      ),
    );
  }

  List<CalendarEvent> _eventsOn(DateTime date) {
    return events
        .where((event) => _sameDate(event.occurrenceAt, date))
        .toList();
  }

  bool _sameDate(DateTime first, DateTime second) {
    return first.year == second.year &&
        first.month == second.month &&
        first.day == second.day;
  }
}

class _CalendarDay extends StatelessWidget {
  const _CalendarDay({
    required this.date,
    required this.selected,
    required this.today,
    required this.events,
    required this.onTap,
  });

  final DateTime date;
  final bool selected;
  final bool today;
  final List<CalendarEvent> events;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final hasAppointment = events.any(
      (event) => event.type == CalendarEventType.appointment,
    );
    final hasImportantDate = events.any(
      (event) => event.type == CalendarEventType.importantDate,
    );

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(14),
      child: Container(
        margin: const EdgeInsets.all(2),
        decoration: BoxDecoration(
          color: selected ? const Color(0xFFA03B56) : Colors.transparent,
          borderRadius: BorderRadius.circular(14),
          border: today && !selected
              ? Border.all(color: const Color(0xFFA03B56))
              : null,
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              date.day.toString(),
              style: TextStyle(
                fontWeight: selected || today
                    ? FontWeight.w800
                    : FontWeight.w500,
                color: selected ? Colors.white : const Color(0xFF30282B),
              ),
            ),
            const SizedBox(height: 5),
            SizedBox(
              height: 6,
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  if (hasAppointment)
                    _EventDot(
                      color: selected ? Colors.white : const Color(0xFF4C79C6),
                    ),
                  if (hasAppointment && hasImportantDate)
                    const SizedBox(width: 3),
                  if (hasImportantDate)
                    _EventDot(
                      color: selected
                          ? const Color(0xFFFFCDD8)
                          : const Color(0xFFA03B56),
                    ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EventDot extends StatelessWidget {
  const _EventDot({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 6,
      height: 6,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
    );
  }
}

class _EventCard extends StatelessWidget {
  const _EventCard({
    required this.event,
    required this.isOpening,
    required this.onTap,
  });

  final CalendarEvent event;
  final bool isOpening;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final isAppointment = event.type == CalendarEventType.appointment;
    final color = isAppointment
        ? const Color(0xFF4C79C6)
        : const Color(0xFFA03B56);

    return Material(
      color: Colors.white,
      borderRadius: BorderRadius.circular(18),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
        child: Container(
          padding: const EdgeInsets.all(15),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: color.withValues(alpha: 0.2)),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(
                  isAppointment
                      ? Icons.event_available_rounded
                      : Icons.favorite_rounded,
                  color: color,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      event.title,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      _subtitle(event),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(color: Color(0xFF756C70)),
                    ),
                  ],
                ),
              ),
              if (isOpening)
                const SizedBox(
                  width: 20,
                  height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              else
                const Icon(
                  Icons.chevron_right_rounded,
                  color: Color(0xFF9A9094),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _subtitle(CalendarEvent event) {
    final parts = <String>[];
    if (event.type == CalendarEventType.appointment) {
      parts.add(DateFormat('HH:mm').format(event.occurrenceAt));
    } else {
      parts.add(
        event.recurrence == CalendarRecurrence.yearly
            ? 'Lặp lại hằng năm'
            : 'Ngày quan trọng',
      );
    }
    if (event.location?.trim().isNotEmpty == true) {
      parts.add(event.location!.trim());
    }
    if (event.reminderEnabled) {
      parts.add(_reminderLabel(event.reminderMinutesBefore));
    }
    return parts.join(' · ');
  }

  String _reminderLabel(int minutes) {
    if (minutes == 0) return 'Nhắc đúng giờ';
    if (minutes % 10080 == 0) return 'Nhắc trước ${minutes ~/ 10080} tuần';
    if (minutes % 1440 == 0) return 'Nhắc trước ${minutes ~/ 1440} ngày';
    if (minutes % 60 == 0) return 'Nhắc trước ${minutes ~/ 60} giờ';
    return 'Nhắc trước $minutes phút';
  }
}

class _EmptyDateCard extends StatelessWidget {
  const _EmptyDateCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 28),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: const Color(0xFFECE3E7)),
      ),
      child: const Column(
        children: [
          Icon(Icons.event_note_outlined, size: 42, color: Color(0xFFB5A9AE)),
          SizedBox(height: 10),
          Text(
            'Ngày này chưa có sự kiện',
            style: TextStyle(
              fontWeight: FontWeight.w700,
              color: Color(0xFF756C70),
            ),
          ),
        ],
      ),
    );
  }
}
