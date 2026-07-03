import 'package:dio/dio.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:lovesync_mobile/features/calendar/domain/entities/calendar_event.dart';
import 'package:lovesync_mobile/features/calendar/domain/usecases/create_calendar_event.dart';
import 'package:lovesync_mobile/features/calendar/domain/usecases/delete_calendar_event.dart';
import 'package:lovesync_mobile/features/calendar/domain/usecases/update_calendar_event.dart';

class CalendarEventFormPage extends StatefulWidget {
  const CalendarEventFormPage({
    super.key,
    required this.createCalendarEvent,
    required this.updateCalendarEvent,
    required this.deleteCalendarEvent,
    this.event,
    this.initialDate,
  });

  final CreateCalendarEvent createCalendarEvent;
  final UpdateCalendarEvent updateCalendarEvent;
  final DeleteCalendarEvent deleteCalendarEvent;
  final CalendarEvent? event;
  final DateTime? initialDate;

  @override
  State<CalendarEventFormPage> createState() => _CalendarEventFormPageState();
}

class _CalendarEventFormPageState extends State<CalendarEventFormPage> {
  static const List<int> _reminderPresets = [0, 30, 60, 1440, 10080];

  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _titleController;
  late final TextEditingController _descriptionController;
  late final TextEditingController _locationController;
  late final TextEditingController _customReminderController;

  late CalendarEventType _type;
  late CalendarRecurrence _recurrence;
  late DateTime _selectedDate;
  late TimeOfDay _selectedTime;
  late bool _reminderEnabled;
  late int _selectedReminder;
  bool _isSaving = false;
  bool _isDeleting = false;

  bool get _isEditing => widget.event != null;

  @override
  void initState() {
    super.initState();
    final event = widget.event;
    final initialDate =
        event?.occurrenceAt ??
        widget.initialDate ??
        DateTime.now().add(const Duration(hours: 1));
    final reminderMinutes = event?.reminderMinutesBefore ?? 1440;

    _titleController = TextEditingController(text: event?.title ?? '');
    _descriptionController = TextEditingController(
      text: event?.description ?? '',
    );
    _locationController = TextEditingController(text: event?.location ?? '');
    _customReminderController = TextEditingController(
      text: _reminderPresets.contains(reminderMinutes)
          ? ''
          : reminderMinutes.toString(),
    );
    _type = event?.type ?? CalendarEventType.appointment;
    _recurrence = event?.recurrence ?? CalendarRecurrence.none;
    _selectedDate = DateTime(
      initialDate.year,
      initialDate.month,
      initialDate.day,
    );
    _selectedTime = TimeOfDay.fromDateTime(initialDate);
    _reminderEnabled = event?.reminderEnabled ?? true;
    _selectedReminder = _reminderPresets.contains(reminderMinutes)
        ? reminderMinutes
        : -1;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _locationController.dispose();
    _customReminderController.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final date = await showDatePicker(
      context: context,
      initialDate: _selectedDate,
      firstDate: DateTime(1900),
      lastDate: DateTime(2100),
      locale: const Locale('vi', 'VN'),
    );
    if (date != null && mounted) setState(() => _selectedDate = date);
  }

  Future<void> _pickTime() async {
    final time = await showTimePicker(
      context: context,
      initialTime: _selectedTime,
    );
    if (time != null && mounted) setState(() => _selectedTime = time);
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate() || _isSaving) return;
    final reminderMinutes = !_reminderEnabled
        ? (_selectedReminder == -1 ? 1440 : _selectedReminder)
        : _selectedReminder == -1
        ? int.parse(_customReminderController.text.trim())
        : _selectedReminder;
    final startsAt = _type == CalendarEventType.importantDate
        ? DateTime(
            _recurrence == CalendarRecurrence.yearly && _isEditing
                ? widget.event!.startsAt.year
                : _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
          )
        : DateTime(
            _selectedDate.year,
            _selectedDate.month,
            _selectedDate.day,
            _selectedTime.hour,
            _selectedTime.minute,
          );
    final location = _locationController.text.trim();
    final input = CalendarEventInput(
      type: _type,
      title: _titleController.text.trim(),
      description: _descriptionController.text.trim(),
      startsAt: startsAt,
      location:
          _type == CalendarEventType.appointment &&
              (location.isNotEmpty || _isEditing)
          ? location
          : null,
      recurrence: _type == CalendarEventType.appointment
          ? CalendarRecurrence.none
          : _recurrence,
      reminderEnabled: _reminderEnabled,
      reminderMinutesBefore: reminderMinutes,
    );

    setState(() => _isSaving = true);
    try {
      if (_isEditing) {
        await widget.updateCalendarEvent(widget.event!.id, input);
      } else {
        await widget.createCalendarEvent(input);
      }
      if (mounted) Navigator.of(context).pop(true);
    } on DioException catch (error) {
      if (!mounted) return;
      _showError(_errorMessage(error));
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _delete() async {
    if (!_isEditing || _isDeleting) return;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Xóa sự kiện?'),
        content: const Text(
          'Sự kiện sẽ bị xóa với cả hai thành viên và không thể khôi phục.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Hủy'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(true),
            style: FilledButton.styleFrom(
              backgroundColor: const Color(0xFFD84A5B),
            ),
            child: const Text('Xóa'),
          ),
        ],
      ),
    );
    if (confirmed != true || !mounted) return;

    setState(() => _isDeleting = true);
    try {
      await widget.deleteCalendarEvent(widget.event!.id);
      if (mounted) Navigator.of(context).pop(true);
    } on DioException catch (error) {
      if (mounted) _showError(_errorMessage(error));
    } finally {
      if (mounted) setState(() => _isDeleting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isImportant = _type == CalendarEventType.importantDate;

    return Scaffold(
      backgroundColor: const Color(0xFFFFF8FA),
      appBar: AppBar(
        automaticallyImplyLeading: false,
        leading: IconButton(
          onPressed: _isSaving || _isDeleting
              ? null
              : () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
          tooltip: 'Đóng',
        ),
        title: Text(
          _isEditing
              ? (isImportant ? 'Ngày quan trọng' : 'Lịch hẹn')
              : 'Thêm sự kiện',
        ),
        backgroundColor: Colors.white,
        actions: [
          if (_isEditing)
            IconButton(
              onPressed: _isDeleting || _isSaving ? null : _delete,
              icon: _isDeleting
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(Icons.delete_outline_rounded),
              color: const Color(0xFFD84A5B),
              tooltip: 'Xóa sự kiện',
            ),
        ],
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.fromLTRB(18, 20, 18, 36),
          children: [
            SegmentedButton<CalendarEventType>(
              segments: const [
                ButtonSegment(
                  value: CalendarEventType.appointment,
                  icon: Icon(Icons.event_available_rounded),
                  label: Text('Lịch hẹn'),
                ),
                ButtonSegment(
                  value: CalendarEventType.importantDate,
                  icon: Icon(Icons.favorite_rounded),
                  label: Text('Ngày quan trọng'),
                ),
              ],
              selected: {_type},
              onSelectionChanged: (selection) {
                setState(() {
                  _type = selection.first;
                  if (_type == CalendarEventType.appointment) {
                    _recurrence = CalendarRecurrence.none;
                  }
                });
              },
            ),
            const SizedBox(height: 20),
            TextFormField(
              controller: _titleController,
              textCapitalization: TextCapitalization.sentences,
              decoration: _inputDecoration(
                'Tiêu đề',
                Icons.title_rounded,
                hint: isImportant ? 'Ngày kỷ niệm' : 'Ăn tối cùng nhau',
              ),
              validator: (value) => value == null || value.trim().isEmpty
                  ? 'Vui lòng nhập tiêu đề'
                  : null,
            ),
            const SizedBox(height: 14),
            TextFormField(
              controller: _descriptionController,
              minLines: 2,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: _inputDecoration(
                'Mô tả',
                Icons.notes_rounded,
                hint: 'Thêm một vài chi tiết...',
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _PickerTile(
                    icon: Icons.calendar_month_rounded,
                    label: 'Ngày',
                    value: DateFormat('dd/MM/yyyy').format(_selectedDate),
                    onTap: _pickDate,
                  ),
                ),
                if (!isImportant) ...[
                  const SizedBox(width: 12),
                  Expanded(
                    child: _PickerTile(
                      icon: Icons.schedule_rounded,
                      label: 'Thời gian',
                      value: _selectedTime.format(context),
                      onTap: _pickTime,
                    ),
                  ),
                ],
              ],
            ),
            if (!isImportant) ...[
              const SizedBox(height: 14),
              TextFormField(
                controller: _locationController,
                textCapitalization: TextCapitalization.sentences,
                decoration: _inputDecoration(
                  'Địa điểm (không bắt buộc)',
                  Icons.location_on_outlined,
                ),
              ),
            ],
            if (isImportant) ...[
              const SizedBox(height: 20),
              const Text(
                'Lặp lại',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              SegmentedButton<CalendarRecurrence>(
                segments: const [
                  ButtonSegment(
                    value: CalendarRecurrence.none,
                    label: Text('Không lặp'),
                  ),
                  ButtonSegment(
                    value: CalendarRecurrence.yearly,
                    label: Text('Hằng năm'),
                  ),
                ],
                selected: {_recurrence},
                onSelectionChanged: (selection) =>
                    setState(() => _recurrence = selection.first),
              ),
            ],
            const SizedBox(height: 18),
            SwitchListTile(
              contentPadding: const EdgeInsets.symmetric(horizontal: 2),
              title: const Text(
                'Nhắc lịch',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              subtitle: const Text('Gửi thông báo cho cả hai'),
              value: _reminderEnabled,
              activeThumbColor: const Color(0xFFA03B56),
              onChanged: (value) => setState(() => _reminderEnabled = value),
            ),
            if (_reminderEnabled) ...[
              const SizedBox(height: 8),
              DropdownButtonFormField<int>(
                initialValue: _selectedReminder,
                decoration: _inputDecoration(
                  'Thời gian nhắc',
                  Icons.notifications_active_outlined,
                ),
                items: const [
                  DropdownMenuItem(value: 0, child: Text('Đúng giờ')),
                  DropdownMenuItem(value: 30, child: Text('Trước 30 phút')),
                  DropdownMenuItem(value: 60, child: Text('Trước 1 giờ')),
                  DropdownMenuItem(value: 1440, child: Text('Trước 1 ngày')),
                  DropdownMenuItem(value: 10080, child: Text('Trước 1 tuần')),
                  DropdownMenuItem(value: -1, child: Text('Tùy chỉnh')),
                ],
                onChanged: (value) =>
                    setState(() => _selectedReminder = value ?? 1440),
              ),
              if (_selectedReminder == -1) ...[
                const SizedBox(height: 12),
                TextFormField(
                  controller: _customReminderController,
                  keyboardType: TextInputType.number,
                  decoration: _inputDecoration(
                    'Số phút trước sự kiện',
                    Icons.timer_outlined,
                    hint: '0 - 525600',
                  ),
                  validator: (value) {
                    if (!_reminderEnabled || _selectedReminder != -1) {
                      return null;
                    }
                    final minutes = int.tryParse(value?.trim() ?? '');
                    if (minutes == null || minutes < 0 || minutes > 525600) {
                      return 'Nhập số phút từ 0 đến 525600';
                    }
                    return null;
                  },
                ),
              ],
            ],
            const SizedBox(height: 26),
            SizedBox(
              height: 52,
              child: FilledButton.icon(
                onPressed: _isSaving || _isDeleting ? null : _save,
                style: FilledButton.styleFrom(
                  backgroundColor: const Color(0xFFA03B56),
                ),
                icon: _isSaving
                    ? const SizedBox(
                        width: 19,
                        height: 19,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Icon(Icons.check_rounded),
                label: Text(_isSaving ? 'Đang lưu...' : 'Lưu sự kiện'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(
    String label,
    IconData icon, {
    String? hint,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: const Color(0xFFA03B56)),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE8DDE2)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE8DDE2)),
      ),
    );
  }

  String _errorMessage(DioException error) {
    final data = error.response?.data;
    if (data is Map) {
      final message = data['message'] ?? data['error'];
      if (message != null) return message.toString();
    }
    return 'Không thể lưu thay đổi. Vui lòng thử lại.';
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), behavior: SnackBarBehavior.floating),
    );
  }
}

class _PickerTile extends StatelessWidget {
  const _PickerTile({
    required this.icon,
    required this.label,
    required this.value,
    required this.onTap,
  });

  final IconData icon;
  final String label;
  final String value;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Ink(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: const Color(0xFFE8DDE2)),
        ),
        child: Row(
          children: [
            Icon(icon, color: const Color(0xFFA03B56)),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: const TextStyle(
                      color: Color(0xFF7D7378),
                      fontSize: 11,
                    ),
                  ),
                  Text(
                    value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w700),
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
