import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/colors.dart';
import '../../models/medication.dart';
import '../../models/appointment.dart';
import '../../services/storage_service.dart';
import '../common/components.dart';
import '../../utils/route_resolver.dart';
import 'add_medication_modal.dart';
import 'add_appointment_modal.dart';

class MedTrackScreen extends StatefulWidget {
  final StorageService storage;

  const MedTrackScreen({super.key, required this.storage});

  @override
  State<MedTrackScreen> createState() => _MedTrackScreenState();
}

class _MedTrackScreenState extends State<MedTrackScreen> {
  List<Medication> _medications = [];
  List<Appointment> _appointments = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  void _loadData() {
    setState(() {
      _medications = widget.storage.getAllMedications();
      _appointments = widget.storage.getAllAppointments();
    });
  }

  Future<void> _showMedicationSheet({Medication? med}) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddMedicationModal(storage: widget.storage, medication: med),
    );
    if (result == true) {
      _loadData();
    }
  }

  Future<void> _showAppointmentSheet({Appointment? appt}) async {
    final result = await showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => AddAppointmentModal(storage: widget.storage, appointment: appt),
    );
    if (result == true) {
      _loadData();
    }
  }

  void _deleteMedication(String id) async {
    await widget.storage.deleteMedication(id);
    _loadData();
  }

  void _deleteAppointment(String id) async {
    await widget.storage.deleteAppointment(id);
    _loadData();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CircaColors.bg,
      appBar: AppBar(
        backgroundColor: CircaColors.bg,
        elevation: 0,
        centerTitle: true,
        leading: const BackButton(color: CircaColors.ink),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: const [
            CircaLogo(size: 17),
            SizedBox(width: 8),
            Text(
              "Medications",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: CircaColors.ink),
            ),
          ],
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("Medications & appointments", style: CircaColors.title),
                    const SizedBox(height: 8),
                    Text(
                      "Add what you take or have coming up. We'll remind you.",
                      style: CircaColors.helpText,
                    ),
                    const SizedBox(height: 40),
                    Text("TRACKING", style: CircaColors.eyebrow),
                    const SizedBox(height: 16),
                    
                    if (_medications.isEmpty && _appointments.isEmpty)
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(24),
                        decoration: BoxDecoration(
                          color: CircaColors.paper,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: CircaColors.line, width: 1.5),
                        ),
                        child: Text(
                          "Nothing here yet. Add a medication or appointment below.",
                          style: CircaColors.helpText.copyWith(fontSize: 14),
                          textAlign: TextAlign.center,
                        ),
                      )
                    else ...[
                      ..._medications.map((m) => _buildMedicationRow(m)).toList(),
                      ..._appointments.map((a) => _buildAppointmentRow(a)).toList(),
                    ],
                      
                    const SizedBox(height: 24),
                    
                    Row(
                      children: [
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _showMedicationSheet(),
                            child: _buildDashedAddTile("+ Add medication"),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: GestureDetector(
                            onTap: () => _showAppointmentSheet(),
                            child: _buildDashedAddTile("+ Add appointment"),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
              child: CircaButton(
                label: "Done",
                onPressed: () {
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => resolveHome(storageService.profile)),
                    (route) => false,
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMedicationRow(Medication med) {
    return Dismissible(
      key: Key('med_${med.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteMedication(med.id),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete_outline, color: Colors.red.shade700),
      ),
      child: GestureDetector(
        onTap: () => _showMedicationSheet(med: med),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CircaColors.paper,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: CircaColors.line, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: CircaColors.accentSoft,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.medication_liquid, color: CircaColors.accentDeep, size: 24), // ◷ Glyph tile equiv
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(med.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(
                      _buildMedScheduleSummary(med),
                      style: CircaColors.helpText.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (med.isReminderEnabled)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: CircaColors.clay.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.notifications_active, size: 14, color: CircaColors.clay),
                ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildAppointmentRow(Appointment appt) {
    return Dismissible(
      key: Key('appt_${appt.id}'),
      direction: DismissDirection.endToStart,
      onDismissed: (_) => _deleteAppointment(appt.id),
      background: Container(
        margin: const EdgeInsets.only(bottom: 12),
        decoration: BoxDecoration(
          color: Colors.red.shade100,
          borderRadius: BorderRadius.circular(14),
        ),
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.only(right: 20),
        child: Icon(Icons.delete_outline, color: Colors.red.shade700),
      ),
      child: GestureDetector(
        onTap: () => _showAppointmentSheet(appt: appt),
        child: Container(
          margin: const EdgeInsets.only(bottom: 12),
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: CircaColors.paper,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(color: CircaColors.line, width: 1.5),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: CircaColors.bg,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: CircaColors.line),
                ),
                child: const Icon(Icons.event, color: CircaColors.ink, size: 24), // ◇ Glyph tile equiv
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(appt.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                    const SizedBox(height: 4),
                    Text(
                      _buildApptSummary(appt),
                      style: CircaColors.helpText.copyWith(fontSize: 13),
                    ),
                  ],
                ),
              ),
              if (appt.isReminderEnabled)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: CircaColors.clay.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Icon(Icons.notifications_active, size: 14, color: CircaColors.clay),
                ),
            ],
          ),
        ),
      ),
    );
  }

  String _buildMedScheduleSummary(Medication med) {
    String summary = "";
    switch (med.frequency) {
      case 'everyday':
        summary = "Everyday";
        break;
      case 'every_week':
        summary = "Every week";
        break;
      case 'specific_days':
        final days = ['Mon', 'Tue', 'Wed', 'Thu', 'Fri', 'Sat', 'Sun'];
        final selectedDaysStr = med.specificDays.map((d) => days[d - 1]).join(', ');
        summary = selectedDaysStr;
        break;
      case 'as_needed':
        return "As needed";
    }

    if (med.times.isNotEmpty) {
      summary += " · ${med.times.join(', ')}";
    }
    return summary;
  }

  String _buildApptSummary(Appointment appt) {
    String summary = DateFormat("MMM d").format(appt.date);
    if (appt.time != null && appt.time!.isNotEmpty) {
      summary += " · ${appt.time}";
    }
    return summary;
  }

  Widget _buildDashedAddTile(String label) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
      decoration: BoxDecoration(
        color: CircaColors.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CircaColors.muted.withOpacity(0.5), width: 1.5),
      ),
      child: Center(
        child: Text(
          label,
          style: const TextStyle(color: CircaColors.muted, fontWeight: FontWeight.w600, fontSize: 14),
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
