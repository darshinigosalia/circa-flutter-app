import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../models/onboarding_data.dart';
import '../../services/storage_service.dart';
import '../common/components.dart';
import '../../models/user_profile.dart';
import '../../utils/route_resolver.dart';

class FertileOptInScreen extends StatelessWidget {
  final OnboardingData data;
  final StorageService? storage;

  const FertileOptInScreen({super.key, required this.data, this.storage});

  Future<void> _completeOnboarding(BuildContext context, OnboardingData finalData) async {
    final activeStorage = storage ?? storageService;
    if (finalData.lastPeriod != null && finalData.cycleType != null && finalData.showFertility != null) {
      final profile = UserProfile(
        cycleType: finalData.cycleType!,
        lastPeriod: finalData.lastPeriod!,
        showFertility: finalData.showFertility!,
      );
      await activeStorage.seedFromOnboarding(profile);
    }
    if (context.mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => resolveHome(activeStorage.profile, activeStorage)),
        (route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        leading: const BackButton(color: CircaColors.ink),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 26),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 16),
              Text("ONE LAST THING", style: CircaColors.eyebrow),
              const SizedBox(height: 12),
              Text("Would you like us to predict your fertile window?", style: CircaColors.title),
              const SizedBox(height: 12),
              Text(
                "Helpful if you're trying to conceive, or avoid it. If not, we'll keep things simple and leave it out entirely.",
                style: CircaColors.helpText,
              ),
              const SizedBox(height: 32),
              CircaChoiceCard(
                icon: Icons.spa_outlined, // Botanical placeholder
                title: "Yes, show my fertile window",
                subtitle: "Predict ovulation and fertile days on my calendar",
                onTap: () => _completeOnboarding(context, data.copyWith(showFertility: true)),
              ),
              const SizedBox(height: 16),
              CircaChoiceCard(
                icon: Icons.grass_outlined, // Botanical placeholder
                title: "No, keep it simple",
                subtitle: "Just track my period and symptoms",
                onTap: () => _completeOnboarding(context, data.copyWith(showFertility: false)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
