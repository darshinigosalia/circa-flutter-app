import 'package:flutter/material.dart';
import '../theme/colors.dart';
import 'components.dart';
import '../models/onboarding_data.dart';
import '../models/cycle_profile.dart';
import '../services/storage_service.dart';
import '../utils/route_resolver.dart';
import 'track_hub_screen.dart';
import 'package:circa_app/utils/app_clock.dart';

class ForgotPeriodScreen extends StatelessWidget {
  final OnboardingData data;

  const ForgotPeriodScreen({super.key, required this.data});

  void _completeOnboarding(BuildContext context) async {
    final profile = CycleProfile(
      track: data.track ?? 'periods',
      fertile: data.fertile ?? false,
      pregnant: data.pregnant ?? false,
      lastPeriod: null, // intentionally null
      cycleLength: 28,
    );

    // Save and resolve home
    await storageService.seedFromOnboarding(profile);
    if (!context.mounted) return;
    
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => resolveHome(profile)),
      (route) => false,
    );
  }

  void _trackSymptom(BuildContext context) async {
    final profile = CycleProfile(
      track: data.track ?? 'periods',
      fertile: data.fertile ?? false,
      pregnant: data.pregnant ?? false,
      lastPeriod: null, // intentionally null
      cycleLength: 28,
    );

    // Save and resolve home
    await storageService.seedFromOnboarding(profile);
    if (!context.mounted) return;
    
    // Clear stack, go to home, then push TrackHubScreen
    Navigator.of(context).pushAndRemoveUntil(
      MaterialPageRoute(builder: (_) => resolveHome(profile)),
      (route) => false,
    );
    // Home routing will handle setting up the home screen, wait a tiny bit to push the next screen
    Future.microtask(() {
      if (!context.mounted) return;
      Navigator.of(context).push(
        MaterialPageRoute(
          builder: (_) => TrackHubScreen(
            date: AppClock.now(),
            data: data,
            storage: storageService,
          ),
        ),
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: CircaColors.paper,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: CircaColors.ink),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text(
                "No worries at all.",
                style: CircaColors.title.copyWith(fontSize: 24),
              ),
              const SizedBox(height: 24),
              Text(
                "We can start whenever your body is ready.",
                style: TextStyle(color: CircaColors.ink, fontSize: 18),
              ),
              const SizedBox(height: 16),
              Text(
                "Nothing to set up now.\nWe'll be here.",
                style: TextStyle(color: CircaColors.ink, fontSize: 18),
              ),
              const Spacer(),
              CircaButton(
                label: "Track a symptom today",
                onPressed: () => _trackSymptom(context),
              ),
              const SizedBox(height: 12),
              CircaButton(
                label: "Got it",
                isGhost: true,
                onPressed: () => _completeOnboarding(context),
              ),
              const SizedBox(height: 12),
              Center(
                child: TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    "I remember now",
                    style: CircaColors.helpText.copyWith(
                      color: CircaColors.muted,
                      decoration: TextDecoration.underline,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 32),
            ],
          ),
        ),
      ),
    );
  }
}
