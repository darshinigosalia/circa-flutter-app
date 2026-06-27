import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../models/onboarding_data.dart';
import '../models/cycle_profile.dart';
import '../services/storage_service.dart';
import '../utils/route_resolver.dart';
import 'components.dart';
import 'med_track_screen.dart';
import 'charts_screen.dart';

class NpMedPromptScreen extends StatefulWidget {
  final OnboardingData data;

  const NpMedPromptScreen({super.key, required this.data});

  @override
  State<NpMedPromptScreen> createState() => _NpMedPromptScreenState();
}

class _NpMedPromptScreenState extends State<NpMedPromptScreen> {
  Future<void> _finishAndNavigate(bool trackMeds, {Widget? nextScreen}) async {
    
    final profile = CycleProfile(
      track: widget.data.track ?? 'noperiods',
      pregnant: widget.data.pregnant ?? false,
      fertile: widget.data.fertile ?? false,
      hormones: widget.data.hormones ?? [],
      anchor: widget.data.anchor,
      symptomsToTrack: widget.data.symptomsToTrack ?? [],
      trackMeds: trackMeds,
    );

    await storageService.saveProfile(profile);

    if (!mounted) return;
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => nextScreen ?? resolveHome(profile)),
      (route) => false,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CircaColors.bg,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: CircaColors.ink),
        title: _buildProgressBar(),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text("CYCLE WITHOUT PERIODS", style: CircaColors.eyebrow),
              const SizedBox(height: 12),
              Text("Would you like to track medications?", style: CircaColors.title),
              const SizedBox(height: 12),
              Text(
                "Set doses and get gentle reminders, or skip straight to your charts. Up to you.",
                style: CircaColors.helpText,
              ),
              const SizedBox(height: 32),
              
              CircaChoiceCard(
                icon: Icons.medication_outlined,
                title: "Yes, track medications",
                subtitle: "Add meds, appointments and reminders",
                onTap: () {
                  _finishAndNavigate(
                    true, 
                    nextScreen: MedTrackScreen(storage: storageService),
                  );
                },
              ),
              const SizedBox(height: 16),
              CircaChoiceCard(
                icon: Icons.bar_chart_outlined,
                title: "Not right now",
                subtitle: "Take me to my charts",
                onTap: () {
                  _finishAndNavigate(false);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildProgressBar() {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(4, (index) {
        return Container(
          width: 24,
          height: 4,
          margin: const EdgeInsets.symmetric(horizontal: 2),
          decoration: BoxDecoration(
            color: index <= 3 ? CircaColors.clay : CircaColors.line,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }
}
