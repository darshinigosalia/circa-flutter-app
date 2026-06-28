import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../models/onboarding_data.dart';
import '../common/components.dart';
import 'np_med_prompt_screen.dart';
import '../../services/storage_service.dart';

class NpSymptomsScreen extends StatefulWidget {
  final OnboardingData data;
  final StorageService? storage;

  const NpSymptomsScreen({super.key, required this.data, this.storage});

  @override
  State<NpSymptomsScreen> createState() => _NpSymptomsScreenState();
}

class _NpSymptomsScreenState extends State<NpSymptomsScreen> {
  final Set<String> _selected = {};

  final List<String> _allSymptoms = [
    "Cramps", "Mood changes", "Fatigue", "Headaches", 
    "Bloating", "Breast tenderness", "Nausea", "Sleep", 
    "Libido", "Skin / acne", "Appetite", "Spotting"
  ];

  void _toggle(String item) {
    setState(() {
      if (_selected.contains(item)) {
        _selected.remove(item);
      } else {
        _selected.add(item);
      }
    });
  }

  void _onContinue() {
    final newData = widget.data.copyWith(symptomsToTrack: _selected.toList());
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => NpMedPromptScreen(data: newData, storage: widget.storage)),
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
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 26),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const SizedBox(height: 16),
                    Text("CYCLE WITHOUT PERIODS", style: CircaColors.eyebrow),
                    const SizedBox(height: 12),
                    Text("What would you like to keep an eye on?", style: CircaColors.title),
                    const SizedBox(height: 12),
                    Text(
                      "Pick as many or as few as you like. Nothing here is required.",
                      style: CircaColors.helpText,
                    ),
                    const SizedBox(height: 32),
                    
                    Wrap(
                      spacing: 8,
                      runSpacing: 12,
                      children: _allSymptoms.map((s) => _buildPill(s)).toList(),
                    ),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
              child: CircaButton(
                label: _selected.isEmpty ? "Skip for now" : "Continue",
                onPressed: _onContinue,
              ),
            ),
          ],
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
            color: index <= 2 ? CircaColors.clay : CircaColors.line,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }

  Widget _buildPill(String label) {
    final isSelected = _selected.contains(label);
    return GestureDetector(
      onTap: () => _toggle(label),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? CircaColors.accentSoft : CircaColors.paper,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(
            color: isSelected ? CircaColors.accentDeep : CircaColors.line, 
            width: 1.5,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              isSelected ? Icons.check_circle : Icons.circle_outlined,
              color: isSelected ? CircaColors.accentDeep : CircaColors.muted,
              size: 20,
            ),
            const SizedBox(width: 8),
            Text(
              label,
              style: TextStyle(
                fontSize: 15,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                color: isSelected ? CircaColors.accentDeep : CircaColors.ink,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
