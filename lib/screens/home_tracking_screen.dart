import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/colors.dart';
import '../services/storage_service.dart';
import '../models/onboarding_data.dart';
import '../models/medication.dart';
import '../models/appointment.dart';
import '../models/day_log.dart';
import 'components.dart';
import 'track_hub_screen.dart';
import 'symptoms_sub_screen.dart';
import 'charts_screen.dart';
import 'circa_drawer.dart';
import 'med_track_screen.dart';
import 'package:circa_app/utils/app_clock.dart';

class ScheduleItem {
  final String id;
  final bool isMedication;
  final String name;
  final String timeText;
  final bool hasReminder;
  final DateTime date;

  ScheduleItem({
    required this.id,
    required this.isMedication,
    required this.name,
    required this.timeText,
    required this.hasReminder,
    required this.date,
  });
}

class HomeTrackingScreen extends StatefulWidget {
  final StorageService storage;

  const HomeTrackingScreen({super.key, required this.storage});

  @override
  State<HomeTrackingScreen> createState() => _HomeTrackingScreenState();
}

class _HomeTrackingScreenState extends State<HomeTrackingScreen> {

  String _normalizeTime(String raw) {
    try {
      if (raw.toLowerCase().contains('a') || raw.toLowerCase().contains('p')) {
        return raw;
      }
      final parts = raw.split(':');
      if (parts.length == 2) {
        final h = int.parse(parts[0]);
        final m = int.parse(parts[1]);
        final ampm = h >= 12 ? 'PM' : 'AM';
        final h12 = h == 0 ? 12 : (h > 12 ? h - 12 : h);
        final mStr = m.toString().padLeft(2, '0');
        return "$h12:$mStr $ampm";
      }
    } catch (_) {}
    return raw;
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.storage,
      builder: (context, _) {
        final profile = widget.storage.profile;
        if (profile == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

        final now = AppClock.now();
        final today = DateTime(now.year, now.month, now.day);
        
        int? dayOf;
        int? nextInDays;
        double logoAngle = 0;

        if (profile.anchor != null) {
          final anchorDateStr = profile.anchor!['date'];
          if (anchorDateStr != null) {
            final anchorDate = DateTime.parse(anchorDateStr);
            final interval = profile.anchor!['interval'] as int;
            
            final anchorNormalized = DateTime(anchorDate.year, anchorDate.month, anchorDate.day);
            final sinceDays = today.difference(anchorNormalized).inDays;
            
            final offset = ((sinceDays % interval) + interval) % interval;
            dayOf = offset + 1;
            nextInDays = interval - offset;
            
            logoAngle = ((dayOf - 1) / interval) * 360;
          }
        }

        List<String> displaySymptoms = profile.symptomsToTrack;
        if (displaySymptoms.isEmpty) {
          displaySymptoms = ["Cramps", "Mood changes", "Fatigue", "Headaches", "Bloating", "Breast tenderness"];
        } else if (displaySymptoms.length > 6) {
          displaySymptoms = displaySymptoms.take(6).toList();
        }

        // --- Schedule Logic ---
        final allMeds = widget.storage.getAllMedications();
        final allAppts = widget.storage.getAllAppointments();

        final todayItems = <ScheduleItem>[];
        final upcomingItems = <ScheduleItem>[];

        // Appointments
        for (var appt in allAppts) {
          final apptNormalized = DateTime(appt.date.year, appt.date.month, appt.date.day);
          final timeStr = appt.time != null ? _normalizeTime(appt.time!) : 'No time';
          
          if (apptNormalized.isAtSameMomentAs(today)) {
            todayItems.add(ScheduleItem(
              id: appt.id, isMedication: false, name: appt.name, 
              timeText: timeStr, hasReminder: appt.isReminderEnabled, date: apptNormalized
            ));
          } else if (apptNormalized.isAfter(today)) {
            upcomingItems.add(ScheduleItem(
              id: appt.id, isMedication: false, name: appt.name, 
              timeText: timeStr, hasReminder: appt.isReminderEnabled, date: apptNormalized
            ));
          }
        }

        // Medications
        for (var med in allMeds) {
          if (med.frequency == 'as_needed') continue;

          final timesStr = med.times.isEmpty ? 'No time' : med.times.map(_normalizeTime).join(', ');
          
          bool isDueToday = false;
          DateTime? nextOccurrence;

          if (med.frequency == 'everyday') {
            isDueToday = true;
            nextOccurrence = today.add(const Duration(days: 1));
          } else if (med.frequency == 'specific_days' || med.frequency == 'every_week') {
            if (med.specificDays.isEmpty) {
              // Sibling of everyday
              isDueToday = true;
              nextOccurrence = today.add(const Duration(days: 1));
            } else {
              isDueToday = med.specificDays.contains(today.weekday);
              
              int minDays = 7;
              for (int d in med.specificDays) {
                int diff = d - today.weekday;
                if (diff <= 0) diff += 7;
                if (diff < minDays) minDays = diff;
              }
              nextOccurrence = today.add(Duration(days: minDays));
            }
          }

          if (isDueToday) {
            todayItems.add(ScheduleItem(
              id: med.id, isMedication: true, name: med.name, 
              timeText: timesStr, hasReminder: med.isReminderEnabled, date: today
            ));
          }
          if (nextOccurrence != null) {
            upcomingItems.add(ScheduleItem(
              id: med.id, isMedication: true, name: med.name, 
              timeText: timesStr, hasReminder: med.isReminderEnabled, date: nextOccurrence
            ));
          }
        }

        upcomingItems.sort((a, b) => a.date.compareTo(b.date));
        final nextFiveUpcoming = upcomingItems.take(5).toList();

        return Scaffold(
          backgroundColor: CircaColors.bg,
          drawer: CircaDrawer(storage: widget.storage, activeRoute: 'Home'),
          appBar: _buildAppBar(logoAngle),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Text(DateFormat("EEEE, MMMM d").format(now).toUpperCase(), style: CircaColors.eyebrow.copyWith(color: CircaColors.accentDeep)),
                      const SizedBox(height: 8),
                      const Text("How are you feeling today?", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 26, color: CircaColors.ink)),
                      const SizedBox(height: 32),

                      if (profile.anchor != null && dayOf != null) ...[
                        Text("YOUR ANCHOR", style: CircaColors.eyebrow),
                        const SizedBox(height: 12),
                        Container(
                          padding: const EdgeInsets.all(20),
                          decoration: BoxDecoration(
                            color: CircaColors.accentSoft,
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: CircaColors.accentDeep, width: 1.5),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(profile.anchor!['type'] ?? 'Anchor', style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                                    const SizedBox(height: 2),
                                    Text("every ${profile.anchor!['interval']} days", style: CircaColors.helpText.copyWith(fontSize: 14)),
                                  ],
                                ),
                              ),
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text("Day $dayOf", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
                                  const SizedBox(height: 2),
                                  Text("next in ${nextInDays}d", style: CircaColors.helpText.copyWith(fontSize: 14)),
                                ],
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 32),
                      ],

                      Text("QUICK LOG", style: CircaColors.eyebrow),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 12,
                        children: [
                          ...displaySymptoms.map((s) => _buildQuickLogChip(s, today, profile)),
                          _buildQuickLogChip("+ More", today, profile),
                        ],
                      ),
                      const SizedBox(height: 32),

                      // TODAY SECTION
                      Text("TODAY", style: CircaColors.eyebrow),
                      const SizedBox(height: 12),
                      if (todayItems.isEmpty)
                        _buildEmptyState("Nothing scheduled today.")
                      else
                        ...todayItems.map((item) => _buildScheduleRow(item)),

                      const SizedBox(height: 32),

                      // UPCOMING SECTION
                      Text("UPCOMING", style: CircaColors.eyebrow),
                      const SizedBox(height: 12),
                      if (nextFiveUpcoming.isEmpty)
                        GestureDetector(
                          onTap: () {
                            Navigator.of(context).push(MaterialPageRoute(builder: (_) => MedTrackScreen(storage: widget.storage)));
                          },
                          child: _buildEmptyState("Nothing scheduled yet. Add a medication or appointment.", isActionable: true),
                        )
                      else
                        ...nextFiveUpcoming.map((item) => _buildScheduleRow(item, showDate: true)),
                      
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),

              // Bottom Action Bar
              Container(
                decoration: const BoxDecoration(
                  color: CircaColors.bg,
                  border: Border(top: BorderSide(color: CircaColors.line, width: 1.5)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: CircaButton(
                          label: "Track",
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => TrackHubScreen(
                                  date: today,
                                  storage: widget.storage,
                                  data: OnboardingData(track: profile.track, pregnant: profile.pregnant, lastPeriod: profile.lastPeriod, fertile: profile.fertile),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: CircaButton(
                          label: "Charts",
                          isGhost: true,
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => ChartsScreen(storage: widget.storage)),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  Widget _buildScheduleRow(ScheduleItem item, {bool showDate = false}) {
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
          Icon(
            item.isMedication ? Icons.medication_liquid : Icons.event,
            color: CircaColors.accentDeep,
            size: 24,
          ),
          const SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  item.name,
                  style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: CircaColors.ink),
                ),
                const SizedBox(height: 2),
                Text(
                  showDate 
                      ? "${DateFormat("MMM d").format(item.date)} • ${item.timeText}"
                      : item.timeText,
                  style: const TextStyle(color: CircaColors.muted, fontSize: 14),
                ),
              ],
            ),
          ),
          if (item.hasReminder)
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: CircaColors.accentSoft,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                "Reminder",
                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: CircaColors.accentDeep),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildEmptyState(String text, {bool isActionable = false}) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CircaColors.bg,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: isActionable ? CircaColors.accent : CircaColors.line, width: 1.5),
      ),
      child: Text(
        text,
        style: CircaColors.helpText.copyWith(
          fontSize: 14, 
          color: isActionable ? CircaColors.accentDeep : CircaColors.muted
        ),
      ),
    );
  }

  Widget _buildQuickLogChip(String label, DateTime date, profile) {
    final isMore = label == '+ More';
    return GestureDetector(
      onTap: () async {
        final existing = widget.storage.getLogForDate(date);
        final draft = existing?.copyWith() ?? DayLog(date: date, loggedAt: AppClock.now());

        final updatedDraft = await Navigator.of(context).push<DayLog>(
          MaterialPageRoute(
            builder: (_) => SymptomsSubScreen(
              draft: draft,
              preSelected: isMore ? null : label,
            ),
          ),
        );

        if (updatedDraft != null && mounted) {
          final data = OnboardingData(
            track: profile.track,
            pregnant: profile.pregnant,
            lastPeriod: profile.lastPeriod,
            fertile: profile.fertile,
          );
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (_) => TrackHubScreen(
                date: date,
                storage: widget.storage,
                data: data,
                initialDraft: updatedDraft,
              ),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isMore ? CircaColors.bg : CircaColors.paper,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: CircaColors.line, width: 1.5),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 15,
            fontWeight: FontWeight.w500,
            color: isMore ? CircaColors.muted : CircaColors.ink,
          ),
        ),
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(double angle) {
    return AppBar(
      backgroundColor: CircaColors.bg,
      elevation: 0,
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.5),
        child: Container(color: CircaColors.line, height: 1.5),
      ),
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, color: CircaColors.ink),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircaLogo(size: 17, angle: angle),
          const SizedBox(width: 8),
          const Text(
            "Today",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: CircaColors.ink),
          ),
        ],
      ),
      actions: const [
        SizedBox(width: 48),
      ],
    );
  }
}
