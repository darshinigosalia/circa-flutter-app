import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../models/medication.dart';
import '../services/storage_service.dart';
import 'package:circa_app/utils/app_clock.dart';

class AddMedicationModal extends StatefulWidget {
  final StorageService storage;
  final Medication? medication;

  const AddMedicationModal({super.key, required this.storage, this.medication});

  @override
  State<AddMedicationModal> createState() => _AddMedicationModalState();
}

class _AddMedicationModalState extends State<AddMedicationModal> {
  final TextEditingController _nameController = TextEditingController();
  String _frequency = 'everyday'; // 'everyday', 'every_week', 'specific_days', 'as_needed'
  final Set<int> _specificDays = {}; // 1..7 for Mon..Sun
  List<TimeOfDay> _selectedTimes = [const TimeOfDay(hour: 8, minute: 0)];
  bool _isReminderEnabled = false;
  String? _errorText;

  @override
  void initState() {
    super.initState();
    if (widget.medication != null) {
      _nameController.text = widget.medication!.name;
      _frequency = widget.medication!.frequency;
      _specificDays.addAll(widget.medication!.specificDays);
      _isReminderEnabled = widget.medication!.isReminderEnabled;
      
      if (widget.medication!.times.isNotEmpty) {
        _selectedTimes = widget.medication!.times.map((t) {
          final parts = t.split(':');
          return TimeOfDay(hour: int.parse(parts[0]), minute: int.parse(parts[1]));
        }).toList();
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
      setState(() => _errorText = "Please enter a medication name.");
      return;
    }
    if (_frequency == 'specific_days' && _specificDays.isEmpty) {
      setState(() => _errorText = "Please select at least one day.");
      return;
    }
    
    // Clear error
    setState(() => _errorText = null);

    final List<String> formattedTimes = _frequency == 'as_needed' 
        ? [] 
        : _selectedTimes.map((t) => "${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}").toList();

    final med = Medication(
      id: widget.medication?.id ?? AppClock.now().millisecondsSinceEpoch.toString(),
      name: name,
      frequency: _frequency,
      specificDays: _frequency == 'specific_days' ? _specificDays.toList() : [],
      times: formattedTimes,
      isReminderEnabled: _isReminderEnabled,
    );

    widget.storage.saveMedication(med);
    Navigator.of(context).pop(true);
  }

  Future<void> _pickTime(int index) async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _selectedTimes[index],
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
        _selectedTimes[index] = picked;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.medication != null;

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
              Text(isEditing ? "Save changes" : "Add medication", style: CircaColors.title.copyWith(fontSize: 20)),
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
              labelText: "Medication name",
              labelStyle: const TextStyle(color: CircaColors.muted),
              filled: true,
              fillColor: CircaColors.bg,
              errorText: _errorText,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14), borderSide: BorderSide.none),
            ),
          ),
          const SizedBox(height: 24),
          
          const Text("FREQUENCY", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: CircaColors.muted)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _buildFreqChip("Everyday", 'everyday'),
              _buildFreqChip("Every Week", 'every_week'),
              _buildFreqChip("Specific Days", 'specific_days'),
              _buildFreqChip("As Needed", 'as_needed'),
            ],
          ),
          
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            child: _frequency == 'specific_days' 
              ? Padding(
                  padding: const EdgeInsets.only(top: 16),
                  child: Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: ["M", "T", "W", "Th", "F", "Sa", "Su"].asMap().entries.map((entry) {
                      final dayIndex = entry.key + 1; // 1..7
                      final isSelected = _specificDays.contains(dayIndex);
                      return ChoiceChip(
                        label: Text(entry.value),
                        selected: isSelected,
                        onSelected: (selected) {
                          setState(() {
                            if (selected) {
                              _specificDays.add(dayIndex);
                            } else {
                              _specificDays.remove(dayIndex);
                            }
                          });
                        },
                        selectedColor: CircaColors.accentSoft,
                        backgroundColor: CircaColors.bg,
                        labelStyle: TextStyle(
                          color: isSelected ? CircaColors.accentDeep : CircaColors.ink,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                        ),
                        side: BorderSide(color: isSelected ? CircaColors.accentDeep : CircaColors.line),
                      );
                    }).toList(),
                  ),
                )
              : const SizedBox.shrink(),
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
          
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            child: _frequency != 'as_needed'
              ? Opacity(
                  opacity: _isReminderEnabled ? 1.0 : 0.5,
                  child: IgnorePointer(
                    ignoring: !_isReminderEnabled,
                    child: Padding(
                      padding: const EdgeInsets.only(top: 16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text("TIMES", style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: CircaColors.muted)),
                          const SizedBox(height: 12),
                          ListView.builder(
                            shrinkWrap: true,
                            physics: const NeverScrollableScrollPhysics(),
                            itemCount: _selectedTimes.length,
                            itemBuilder: (context, index) {
                              return Padding(
                                padding: const EdgeInsets.only(bottom: 8),
                                child: Row(
                                  children: [
                                    Expanded(
                                      child: GestureDetector(
                                        onTap: () => _pickTime(index),
                                        child: Container(
                                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                                          decoration: BoxDecoration(
                                            color: CircaColors.bg,
                                            borderRadius: BorderRadius.circular(14),
                                          ),
                                          child: Text(
                                            _selectedTimes[index].format(context),
                                            style: const TextStyle(fontSize: 16),
                                          ),
                                        ),
                                      ),
                                    ),
                                    if (_selectedTimes.length > 1)
                                      IconButton(
                                        icon: const Icon(Icons.remove_circle_outline, color: CircaColors.muted),
                                        onPressed: () {
                                          setState(() {
                                            _selectedTimes.removeAt(index);
                                          });
                                        },
                                      ),
                                  ],
                                ),
                              );
                            },
                          ),
                          TextButton.icon(
                            onPressed: () {
                              setState(() {
                                _selectedTimes.add(const TimeOfDay(hour: 12, minute: 0));
                              });
                            },
                            icon: const Icon(Icons.add, color: CircaColors.accentDeep, size: 20),
                            label: const Text("Add another time", style: TextStyle(color: CircaColors.accentDeep)),
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                              minimumSize: Size.zero,
                              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              : const SizedBox.shrink(),
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
              child: Text(isEditing ? "Save changes" : "Add medication"),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFreqChip(String label, String value) {
    final isSelected = _frequency == value;
    return ChoiceChip(
      label: Text(label),
      selected: isSelected,
      onSelected: (selected) {
        if (selected) {
          setState(() {
            _frequency = value;
            // Clear specific days if changing away from it
            if (value != 'specific_days') {
              _specificDays.clear();
            }
          });
        }
      },
      selectedColor: CircaColors.accentSoft,
      backgroundColor: CircaColors.bg,
      labelStyle: TextStyle(
        color: isSelected ? CircaColors.accentDeep : CircaColors.ink,
        fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
      ),
      side: BorderSide(color: isSelected ? CircaColors.accentDeep : CircaColors.line),
    );
  }
}
