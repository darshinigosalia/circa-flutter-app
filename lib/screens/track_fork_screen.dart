import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../models/onboarding_data.dart';
import 'components.dart';
import 'date_entry_screen.dart';
import 'pregnancy_question_screen.dart';

class TrackForkScreen extends StatelessWidget {
  final OnboardingData data;

  const TrackForkScreen({super.key, required this.data});

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
              Text("GETTING STARTED", style: CircaColors.eyebrow),
              const SizedBox(height: 12),
              Text("What would you like to track?", style: CircaColors.title),
              const SizedBox(height: 12),
              Text(
                "There's no wrong answer; you can always change this later.",
                style: CircaColors.helpText,
              ),
              const SizedBox(height: 32),
              CircaChoiceCard(
                icon: Icons.water_drop_outlined, // Nature/botanical placeholder
                title: "I have a menstrual cycle",
                subtitle: "I have a monthly bleed I'd like to follow (even if it is irregular)",
                onTap: () {
                  final newData = data.copyWith(track: 'periods', pregnant: false);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => DateEntryScreen(data: newData)),
                  );
                },
              ),
              const SizedBox(height: 16),
              CircaChoiceCard(
                icon: Icons.eco_outlined, // Botanical placeholder
                title: "I don't currently have a period",
                subtitle: "Pregnancy, hormones, menopause, or no bleed right now",
                onTap: () {
                  final newData = data.copyWith(track: 'noperiods');
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => PregnancyQuestionScreen(data: newData)),
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
