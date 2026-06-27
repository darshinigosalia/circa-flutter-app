import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../services/storage_service.dart';
import '../utils/cycle_extractor.dart';

class ChartsCyclesTab extends StatefulWidget {
  final StorageService storage;

  const ChartsCyclesTab({super.key, required this.storage});

  @override
  State<ChartsCyclesTab> createState() => _ChartsCyclesTabState();
}

class _ChartsCyclesTabState extends State<ChartsCyclesTab> {
  final Map<int, bool> _expanded = {};

  void _toggleAnomalous(CycleData cycle, bool isAnomalous) async {
    // Anomalous flag is stored on the start day's log
    final startLog = widget.storage.getLogForDate(cycle.startDate);
    if (startLog != null) {
      final updated = startLog.copyWith(anomalousCycle: isAnomalous, anomalousReason: isAnomalous ? startLog.anomalousReason : null);
      await widget.storage.saveLog(updated);
      setState(() {});
    }
  }

  void _updateReason(CycleData cycle, String reason) async {
    final startLog = widget.storage.getLogForDate(cycle.startDate);
    if (startLog != null) {
      final updated = startLog.copyWith(anomalousReason: reason);
      await widget.storage.saveLog(updated);
      setState(() {});
    }
  }

  @override
  Widget build(BuildContext context) {
    final allLogs = widget.storage.getAllLogs();
    final cycles = CycleExtractor.extractCycles(allLogs);

    if (cycles.isEmpty) {
      return const Center(
        child: Padding(
          padding: EdgeInsets.all(32.0),
          child: Text(
            "Your cycles will appear here once you log a period.",
            style: TextStyle(fontSize: 16, color: CircaColors.muted),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 26),
      itemCount: cycles.length,
      itemBuilder: (context, index) {
        final cycle = cycles[index];
        final isCurrent = index == 0 && cycle.endDate == null;
        final isExpanded = _expanded[cycle.number] ?? false;

        return Container(
          margin: const EdgeInsets.only(bottom: 12),
          decoration: BoxDecoration(
            color: isCurrent ? CircaColors.apricot.withValues(alpha: 0.5) : CircaColors.paper,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: isCurrent ? CircaColors.clay : CircaColors.line, width: 1.5),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              InkWell(
                onTap: () {
                  setState(() {
                    _expanded[cycle.number] = !isExpanded;
                  });
                },
                borderRadius: BorderRadius.circular(16),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            if (isCurrent)
                              Text("Current cycle · in progress · tracking", style: CircaColors.eyebrow.copyWith(color: CircaColors.clay)),
                            if (isCurrent) const SizedBox(height: 8),
                            if (!isCurrent)
                              Text("Cycle ${cycle.number}", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: CircaColors.ink)),
                            if (!isCurrent) const SizedBox(height: 4),
                            if (!isCurrent)
                              Text("${cycle.length} days · ${cycle.bleedingDays} bleeding days", style: const TextStyle(fontSize: 14, color: CircaColors.muted)),
                          ],
                        ),
                      ),
                      Icon(isExpanded ? Icons.keyboard_arrow_up : Icons.keyboard_arrow_down, color: CircaColors.muted),
                    ],
                  ),
                ),
              ),
              if (isExpanded)
                Padding(
                  padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Divider(color: CircaColors.line, height: 1),
                      const SizedBox(height: 16),
                      const Text("Symptoms logged", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: CircaColors.ink)),
                      const SizedBox(height: 12),
                      _buildSymptomChips(cycle),
                      const SizedBox(height: 24),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const Text("Mark cycle anomalous", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14, color: CircaColors.ink)),
                          Switch(
                            value: cycle.anomalous,
                            onChanged: (val) => _toggleAnomalous(cycle, val),
                            activeThumbColor: CircaColors.clay,
                            activeTrackColor: CircaColors.clay.withValues(alpha: 0.3),
                          ),
                        ],
                      ),
                      if (cycle.anomalous) ...[
                        const SizedBox(height: 12),
                        const Text(
                          "This cycle won't be counted when predicting your next period.",
                          style: TextStyle(fontSize: 13, color: CircaColors.muted, fontStyle: FontStyle.italic),
                        ),
                        const SizedBox(height: 12),
                        TextField(
                          onChanged: (val) => _updateReason(cycle, val),
                          controller: TextEditingController.fromValue(
                            TextEditingValue(
                              text: cycle.anomalousReason ?? "",
                              selection: TextSelection.collapsed(offset: (cycle.anomalousReason ?? "").length),
                            ),
                          ),
                          style: const TextStyle(fontSize: 14),
                          decoration: InputDecoration(
                            hintText: "Why was this cycle unusual? (stress, travel...)",
                            filled: true,
                            fillColor: CircaColors.bg,
                            isDense: true,
                            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: CircaColors.line),
                            ),
                            enabledBorder: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(12),
                              borderSide: const BorderSide(color: CircaColors.line),
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  Widget _buildSymptomChips(CycleData cycle) {
    Set<String> uniqueSymptoms = {};
    for (final log in cycle.logs) {
      if (log.bleedingFlowLevel != null) uniqueSymptoms.add("Bleeding");
      if (log.dischargeAmount != null) uniqueSymptoms.add("Discharge");
      uniqueSymptoms.addAll(log.symptoms.keys);
      uniqueSymptoms.addAll(log.customSymptoms.map((c) => c.name));
    }

    if (uniqueSymptoms.isEmpty) {
      return const Text("None", style: TextStyle(color: CircaColors.muted, fontSize: 14));
    }

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: uniqueSymptoms.map((s) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
          decoration: BoxDecoration(
            color: CircaColors.bg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: CircaColors.line),
          ),
          child: Text(s, style: const TextStyle(fontSize: 13, color: CircaColors.ink)),
        );
      }).toList(),
    );
  }
}
