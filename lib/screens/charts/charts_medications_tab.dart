import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../services/storage_service.dart';
import '../../models/medication.dart';
import '../../models/appointment.dart';

class ChartsMedicationsTab extends StatelessWidget {
  final StorageService storage;

  const ChartsMedicationsTab({super.key, required this.storage});

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: storage,
      builder: (context, _) {
        final meds = storage.getAllMedications();
        final appts = storage.getAllAppointments();

        if (meds.isEmpty && appts.isEmpty) {
          return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: CircaColors.paper,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: CircaColors.line, width: 1.5),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.medication_outlined, color: CircaColors.muted, size: 32),
                      const SizedBox(height: 16),
                      Text(
                        "Nothing to chart yet. Add a medication to see it here.",
                        style: CircaColors.helpText.copyWith(fontSize: 14),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
        }

        return ListView(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 32),
          children: [
            if (meds.isNotEmpty) ...[
              Text("MEDICATIONS", style: CircaColors.eyebrow),
              const SizedBox(height: 12),
              ...meds.map((m) => _buildSimpleMedRow(m)),
              const SizedBox(height: 32),
            ],
            if (appts.isNotEmpty) ...[
              Text("APPOINTMENTS", style: CircaColors.eyebrow),
              const SizedBox(height: 12),
              ...appts.map((a) => _buildSimpleApptRow(a)),
            ],
          ],
        );
      }
    );
  }

  Widget _buildSimpleMedRow(Medication med) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
            child: const Icon(Icons.medication_liquid, color: CircaColors.accentDeep, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(med.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          ),
        ],
      ),
    );
  }

  Widget _buildSimpleApptRow(Appointment appt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
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
            child: const Icon(Icons.event, color: CircaColors.ink, size: 24),
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Text(appt.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          ),
        ],
      ),
    );
  }
}
