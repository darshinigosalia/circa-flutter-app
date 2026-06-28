import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/colors.dart';
import '../../services/storage_service.dart';
import '../../utils/pregnancy_math.dart';
import '../../models/onboarding_data.dart';
import '../../models/cycle_type.dart';
import '../common/components.dart';
import '../track/track_hub_screen.dart';
import '../common/coming_soon_screen.dart';
import '../onboarding/gestation_date_screen.dart';
import '../charts/charts_screen.dart';
import '../track/med_track_screen.dart';
import '../common/circa_drawer.dart';
import '../../models/medication.dart';
import '../../models/appointment.dart';
import 'package:circa_app/utils/app_clock.dart';

class PregnancyHomeScreen extends StatefulWidget {
  final StorageService storage;

  const PregnancyHomeScreen({super.key, required this.storage});

  @override
  State<PregnancyHomeScreen> createState() => _PregnancyHomeScreenState();
}

class _PregnancyHomeScreenState extends State<PregnancyHomeScreen> {

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.storage,
      builder: (context, _) {
        final profile = widget.storage.profile;
        if (profile == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

        final lastPeriod = profile.lastPeriod;
        if (lastPeriod == null) {
          WidgetsBinding.instance.addPostFrameCallback((_) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(
                builder: (_) => GestationDateScreen(
                  data: OnboardingData(cycleType: profile.cycleType, isPregnant: profile.isPregnant),
                ),
              ),
            );
          });
          return const Scaffold(body: Center(child: CircularProgressIndicator()));
        }

        final today = AppClock.now();

        final elapsedDays = PregnancyMath.getElapsedDays(lastPeriod, today);
        final weeks = PregnancyMath.getWeeks(elapsedDays);
        final days = PregnancyMath.getDays(elapsedDays);
        final dueDate = PregnancyMath.getDueDate(lastPeriod);
        final daysToDue = PregnancyMath.getDaysToDue(dueDate, today);
        final months = PregnancyMath.getMonths(weeks);
        final trimester = PregnancyMath.getTrimester(weeks);
        final logoAngle = PregnancyMath.getLogoAngle(elapsedDays);

        final monthLabel = months == 1 ? "1 month" : "$months months";

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
                      Text("${trimester.toUpperCase()} TRIMESTER", style: CircaColors.eyebrow.copyWith(color: CircaColors.accentDeep)),
                      const SizedBox(height: 8),
                      Text("$weeks weeks, $days days", style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 26, color: CircaColors.ink)),
                      const SizedBox(height: 6),
                      Text(
                        "About $monthLabel along. Congratulations; we'll walk this with you.",
                        style: CircaColors.helpText,
                      ),
                      const SizedBox(height: 32),
                      
                      // Two pills side by side
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryPill(
                              "LAST PERIOD",
                              DateFormat("MMM d").format(lastPeriod),
                              null,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _buildSummaryPill(
                              "DUE DATE",
                              DateFormat("MMM d").format(dueDate),
                              "in $daysToDue days",
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      // Upcoming block
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("UPCOMING", style: CircaColors.eyebrow),
                          TextButton(
                            onPressed: () {
                              Navigator.of(context).push(
                                MaterialPageRoute(builder: (_) => const ComingSoonScreen()),
                              );
                            },
                            child: const Text("Manage", style: TextStyle(color: CircaColors.muted, fontSize: 14, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Upcoming content
                      Builder(
                        builder: (context) {
                          final meds = widget.storage.getAllMedications();
                          final appts = widget.storage.getAllAppointments();
                          
                          if (meds.isEmpty && appts.isEmpty) {
                            return Container(
                              width: double.infinity,
                              padding: const EdgeInsets.all(20),
                              decoration: BoxDecoration(
                                color: CircaColors.paper,
                                borderRadius: BorderRadius.circular(14),
                                border: Border.all(color: CircaColors.line, width: 1.5),
                              ),
                              child: Text(
                                "Nothing scheduled yet. Add a medication or appointment.",
                                style: CircaColors.helpText.copyWith(fontSize: 14),
                                textAlign: TextAlign.center,
                              ),
                            );
                          }
                          
                          return Column(
                            children: [
                              ...meds.map((m) => _buildSimpleMedRow(m)),
                              ...appts.map((a) => _buildSimpleApptRow(a)),
                            ],
                          );
                        }
                      ),
                      const SizedBox(height: 24),
                      
                      // Soft Note card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: CircaColors.bg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: CircaColors.line, width: 1.5),
                        ),
                        child: Text(
                          "Add medications or appointments and we'll send reminders. You can also log symptoms or notes any day.",
                          style: CircaColors.helpText.copyWith(fontSize: 14),
                        ),
                      ),
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
                                  date: AppClock.now(),
                                  storage: widget.storage,
                                  data: OnboardingData(
                                    cycleType: profile.cycleType,
                                    isPregnant: profile.isPregnant,
                                    lastPeriod: profile.lastPeriod,
                                    isFertile: profile.isFertile,
                                  ),
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
            "Your pregnancy",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: CircaColors.ink),
          ),
        ],
      ),
      actions: const [
        SizedBox(width: 48),
      ],
    );
  }

  Widget _buildSummaryPill(String eyebrow, String title, String? sub) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CircaColors.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CircaColors.line, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(eyebrow, style: CircaColors.eyebrow),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          if (sub != null) ...[
            const SizedBox(height: 2),
            Text(sub, style: CircaColors.helpText.copyWith(fontSize: 14)),
          ],
        ],
      ),
    );
  }

  Widget _buildSimpleMedRow(Medication med) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CircaColors.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CircaColors.line, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: CircaColors.accentSoft,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Icon(Icons.medication_liquid, color: CircaColors.accentDeep, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(med.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          ),
          if (med.isReminderEnabled)
            const Icon(Icons.notifications_active, size: 14, color: CircaColors.clay),
        ],
      ),
    );
  }

  Widget _buildSimpleApptRow(Appointment appt) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: CircaColors.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CircaColors.line, width: 1.5),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: CircaColors.bg,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: CircaColors.line),
            ),
            child: const Icon(Icons.event, color: CircaColors.ink, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(appt.name, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 15)),
          ),
          if (appt.isReminderEnabled)
            const Icon(Icons.notifications_active, size: 14, color: CircaColors.clay),
        ],
      ),
    );
  }
}
