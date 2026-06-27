import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/colors.dart';
import '../models/appointment.dart';
import '../services/storage_service.dart';
import 'package:circa_app/utils/app_clock.dart';

class AddAppointmentModal extends StatefulWidget {
  final StorageService storage;
  final Appointment? appointment;

  const AddAppointmentModal({super.key, required this.storage, this.appointment});

  @override
  State<AddAppointmentModal> createState() => _AddAppointmentModalState();
}

class _AddAppointmentModalState extends State<AddAppointmentModal> {
  final TextEditingController _nameController = TextEditingController();
  DateTime? _selectedDate;
  TimeOfDay? _selectedTime;
  bool _isReminderEnabled = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    if (widget.appointment != null) {
      _nameController.text = widget.appointment!.name;
      _selectedDate = widget.appointment!.date;
      _isReminderEnabled = widget.appointment!.isReminderEnabled;
      
      if (widget.appointment!.time != null) {
        // Simple parse assuming HH:mm or similar formatted from TimeOfDay
        // Since we save it using TimeOfDay.format, we'll try to reconstruct.
        // Actually TimeOfDay formatting is localized. Let's just default to null if editing is tricky, 
        // or parse robustly. For this stub, we'll try to parse if it's "HH:mm".
        try {
          final parts = widget.appointment!.time!.split(':');
          if (parts.length >= 2) {
            final hour = int.parse(parts[0].replaceAll(RegExp(r'[^0-9]'), ''));
            final min = int.parse(parts[1].replaceAll(RegExp(r'[^0-9]'), ''));
            _selectedTime = TimeOfDay(hour: hour, minute: min);
          }
        } catch (_) {}
      }
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _save() {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      setState(() => _errorText = "Please enter an appointment name.");
      return;
    }
    if (_selectedDate == null) {
      setState(() => _errorText = "Please select a date.");
      return;
    }
    
    setState(() => _errorText = null);

    final String? timeString = _selectedTime?.format(context);

    final appt = Appointment(
      id: widget.appointment?.id ?? AppClock.now().millisecondsSinceEpoch.toString(),
      name: name,
      date: _selectedDate!,
      time: timeString,
      isReminderEnabled: _isReminderEnabled,
    );

    widget.storage.saveAppointment(appt);
    Navigator.of(context).pop(true);
  }

  Future<void> _pickDate() async {
    final now = AppClock.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now.add(const Duration(days: 365 * 2)),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: CircaColors.clay,
              onPrimary: Colors.white,
              surface: CircaColors.bg,
              onSurface: CircaColors.ink,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTime ?? const TimeOfDay(hour: 9, minute: 0),
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: CircaColors.clay,
              onPrimary: Colors.white,
              surface: CircaColors.bg,
              onSurface: CircaColors.ink,
            ),
          ),
          child: child!,
        );
      },
    );
    if (picked != null) {
      setState(() {
        _selectedTime = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.appointment != null;

    return Container(
      padding: EdgeInsets.only(
        bottom: MediaQuery.of(context).viewInsets.bottom + 32,
        left: 26,
        right: 26,
        top: 16,
      ),
      decoration: const BoxDecoration(
        color: CircaColors.paper,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: CircaColors.line,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(isEditing ? "Save changes" : "Add appointment", style: CircaColors.title.copyWith(fontSize: 20)),
              IconButton(
                icon: const Icon(Icons.close),
                onPressed: () => Navigator.pop(context),
              ),
            ],
          ),
          const SizedBox(height: 24),
          
          TextField(
            controller: _nameController,
            decoration: InputDecoration(
              labelText: "Appointment name",
              labelStyle: const TextStyle(color: CircaColors.muted),
              filled: true,
              fillColor: CircaColors.bg,
              errorText: _errorText,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: GestureDetector(
                  onTap: _pickDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: CircaColors.bg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      _selectedDate != null ? DateFormat.yMMMd().format(_selectedDate!) : "Date",
                      style: TextStyle(color: _selectedDate != null ? CircaColors.ink : CircaColors.muted, fontSize: 16),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: GestureDetector(
                  onTap: _pickTime,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                    decoration: BoxDecoration(
                      color: CircaColors.bg,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Text(
                      _selectedTime != null ? _selectedTime!.format(context) : "Time (opt)",
                      style: TextStyle(color: _selectedTime != null ? CircaColors.ink : CircaColors.muted, fontSize: 16),
                    ),
                  ),
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text("Reminder", style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
              Switch(
                value: _isReminderEnabled,
                onChanged: (val) => setState(() => _isReminderEnabled = val),
                activeTrackColor: CircaColors.clay.withOpacity(0.3),
                activeThumbColor: CircaColors.clay,
              ),
            ],
          ),
          
          const SizedBox(height: 32),
          SizedBox(
            width: double.infinity,
            height: 56,
            child: ElevatedButton(
              onPressed: _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: CircaColors.accentDeep,
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600, fontFamily: 'HankenGrotesque'),
              ),
              child: Text(isEditing ? "Save changes" : "Add appointment"),
            ),
          ),
        ],
      ),
    );
  }
}
