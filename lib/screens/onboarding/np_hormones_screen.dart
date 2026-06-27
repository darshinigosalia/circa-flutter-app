import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../models/onboarding_data.dart';
import '../common/components.dart';
import 'np_anchor_screen.dart';

class NpHormonesScreen extends StatefulWidget {
  final OnboardingData data;

  const NpHormonesScreen({super.key, required this.data});

  @override
  State<NpHormonesScreen> createState() => _NpHormonesScreenState();
}

class _NpHormonesScreenState extends State<NpHormonesScreen> {
  final Set<String> _selected = {};
  bool _otherSelected = false;
  final TextEditingController _otherController = TextEditingController();

  void _toggle(String item) {
    setState(() {
      if (_selected.contains(item)) {
        _selected.remove(item);
        if (item == 'Other') _otherSelected = false;
      } else {
        _selected.add(item);
        if (item == 'Other') _otherSelected = true;
      }
    });
  }

  void _onContinue() {
    List<String> hormones = _selected.where((i) => i != 'Other').toList();
    if (_otherSelected && _otherController.text.trim().isNotEmpty) {
      hormones.add('Other: ${_otherController.text.trim()}');
    }

    final newData = widget.data.copyWith(hormones: hormones);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => NpAnchorScreen(data: newData)),
    );
  }

  @override
  void dispose() {
    _otherController.dispose();
    super.dispose();
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
                    Text("Are you using any contraception or hormones?", style: CircaColors.title),
                    const SizedBox(height: 12),
                    Text(
                      "Totally optional. We'll factor this in to give you a clearer view of your cycle patterns.",
                      style: CircaColors.helpText,
                    ),
                    const SizedBox(height: 32),
                    
                    _buildCategory("CONTRACEPTION", [
                      "Birth control pill",
                      "IUD",
                      "Implant / patch",
                    ]),
                    
                    _buildCategory("HORMONE THERAPY", [
                      "Gender-affirming hormone therapy (GAHT)",
                      "Testosterone",
                      "Hormone replacement therapy (HRT)",
                    ]),
                    
                    _buildCategory("OTHER", [
                      "Fertility medication",
                      "Other",
                    ]),
                    
                    AnimatedSize(
                      duration: const Duration(milliseconds: 250),
                      child: _otherSelected 
                          ? Padding(
                              padding: const EdgeInsets.only(top: 8, bottom: 24),
                              child: TextField(
                                controller: _otherController,
                                decoration: InputDecoration(
                                  hintText: "Enter details",
                                  hintStyle: const TextStyle(color: CircaColors.muted),
                                  filled: true,
                                  fillColor: CircaColors.paper,
                                  border: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: CircaColors.line, width: 1.5),
                                  ),
                                  enabledBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: CircaColors.line, width: 1.5),
                                  ),
                                  focusedBorder: OutlineInputBorder(
                                    borderRadius: BorderRadius.circular(14),
                                    borderSide: const BorderSide(color: CircaColors.clay, width: 2),
                                  ),
                                ),
                              ),
                            )
                          : const SizedBox.shrink(),
                    ),
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
              child: CircaButton(
                label: _selected.isEmpty ? "None right now" : "Continue",
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
            color: index == 0 ? CircaColors.clay : CircaColors.line,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }

  Widget _buildCategory(String title, List<String> items) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: CircaColors.muted, letterSpacing: 0.5)),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            runSpacing: 12,
            children: items.map((item) => _buildPill(item)).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildPill(String label) {
    final isSelected = _selected.contains(label);
    return GestureDetector(
      onTap: () => _toggle(label),
      child: Container(
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width - 52),
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
            Flexible(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 15,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  color: isSelected ? CircaColors.accentDeep : CircaColors.ink,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
