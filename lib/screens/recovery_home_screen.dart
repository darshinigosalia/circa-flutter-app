import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/colors.dart';
import '../services/storage_service.dart';
import '../models/onboarding_data.dart';
import '../models/day_log.dart';
import 'components.dart';
import 'track_hub_screen.dart';
import 'symptoms_sub_screen.dart';
import 'charts_screen.dart';
import 'circa_drawer.dart';
import 'package:circa_app/utils/app_clock.dart';

class RecoveryHomeScreen extends StatefulWidget {
  final StorageService storage;

  const RecoveryHomeScreen({super.key, required this.storage});

  @override
  State<RecoveryHomeScreen> createState() => _RecoveryHomeScreenState();
}

class _RecoveryHomeScreenState extends State<RecoveryHomeScreen> {
  final List<String> _quickLogSymptoms = [
    'Mood',
    'Bleeding',
    'Cramps',
    'Sleep',
    'Energy'
  ];

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.storage,
      builder: (context, _) {
        final profile = widget.storage.profile;
        if (profile == null) return const Scaffold(body: Center(child: CircularProgressIndicator()));

        final today = AppClock.now();

        return Scaffold(
          backgroundColor: CircaColors.bg,
          drawer: CircaDrawer(storage: widget.storage, activeRoute: 'Home'),
          appBar: _buildAppBar(),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Text(DateFormat('EEEE, MMMM d').format(today).toUpperCase(), style: CircaColors.eyebrow),
                      const SizedBox(height: 8),
                      Text("Be gentle with yourself", style: CircaColors.title),
                      const SizedBox(height: 6),
                      Text(
                        "We're holding space for you. There's nothing you need to do here, only what feels right.",
                        style: CircaColors.helpText,
                      ),
                      const SizedBox(height: 32),
                      
                      // Quick Log
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text("IF YOU'D LIKE TO LOG SOMETHING", style: CircaColors.eyebrow),
                          TextButton(
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
                            child: const Text("Edit", style: TextStyle(color: CircaColors.muted, fontSize: 14, fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 12,
                        children: [
                          ..._quickLogSymptoms.map((symptom) => _buildSymptomChip(symptom)),
                          _buildAddMoreChip(),
                        ],
                      ),
                      const SizedBox(height: 32),
                      
                      // Note card
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: CircaColors.bg,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: CircaColors.line, width: 1.5),
                        ),
                        child: Text(
                          "We've paused all predictions for a few weeks. Cycles after a loss can be irregular, so for now we'll simply follow how you feel, and ease predictions back in only when you're ready.",
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

  PreferredSizeWidget _buildAppBar() {
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
      title: const CircaLogo(size: 17),
      actions: const [
        SizedBox(width: 48),
      ],
    );
  }

  /// Opens SymptomsSubScreen with the chip label pre-selected, then chains
  /// to TrackHubScreen so the user can finish the rest of the entry.
  void _onChipTap(String? preSelected) async {
    final now = AppClock.now();
    final today = DateTime(now.year, now.month, now.day);
    final existing = widget.storage.getLogForDate(today);
    final draft = existing?.copyWith() ?? DayLog(date: today, loggedAt: now);

    final updatedDraft = await Navigator.of(context).push<DayLog>(
      MaterialPageRoute(
        builder: (_) => SymptomsSubScreen(
          draft: draft,
          preSelected: preSelected,
        ),
      ),
    );

    if (updatedDraft != null && mounted) {
      final profile = widget.storage.profile;
      final data = OnboardingData(
        track: profile?.track,
        pregnant: profile?.pregnant,
        lastPeriod: profile?.lastPeriod,
        fertile: profile?.fertile,
      );
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => TrackHubScreen(
            date: today,
            storage: widget.storage,
            data: data,
            initialDraft: updatedDraft,
          ),
        ),
      );
    }
  }

  Widget _buildSymptomChip(String label) {
    return GestureDetector(
      onTap: () => _onChipTap(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: CircaColors.paper,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: CircaColors.line),
        ),
        child: Text(
          label,
          style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: CircaColors.ink),
        ),
      ),
    );
  }

  Widget _buildAddMoreChip() {
    return GestureDetector(
      onTap: () => _onChipTap(null),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: CircaColors.bg,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: CircaColors.line, style: BorderStyle.solid),
        ),
        child: const Text(
          "+ More",
          style: TextStyle(fontWeight: FontWeight.w500, fontSize: 14, color: CircaColors.muted),
        ),
      ),
    );
  }
}
