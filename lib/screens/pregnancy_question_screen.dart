import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../models/onboarding_data.dart';
import 'components.dart';
import 'gestation_date_screen.dart';
import 'np_hormones_screen.dart';

class PregnancyQuestionScreen extends StatelessWidget {
  final OnboardingData data;

  const PregnancyQuestionScreen({super.key, required this.data});

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
              Text("Would you like to include pregnancy tracking?", style: CircaColors.title),
              const SizedBox(height: 12),
              Text(
                "This helps us set up the right dashboard for you.",
                style: CircaColors.helpText,
              ),
              const SizedBox(height: 32),
              CircaChoiceCard(
                icon: Icons.child_care_outlined, // Placeholder icon
                title: "Yes, please",
                subtitle: "",
                onTap: () {
                  final newData = data.copyWith(pregnant: true);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => GestationDateScreen(data: newData)),
                  );
                },
              ),
              const SizedBox(height: 16),
              CircaChoiceCard(
                icon: Icons.help_outline, // Placeholder icon
                title: "No, or not sure",
                subtitle: "",
                onTap: () {
                  final newData = data.copyWith(pregnant: false);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => NpHormonesScreen(data: newData)),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
