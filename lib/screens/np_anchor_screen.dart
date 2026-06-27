import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/colors.dart';
import '../models/onboarding_data.dart';
import 'components.dart';
import 'np_symptoms_screen.dart';
import 'package:circa_app/utils/app_clock.dart';

class NpAnchorScreen extends StatefulWidget {
  final OnboardingData data;

  const NpAnchorScreen({super.key, required this.data});

  @override
  State<NpAnchorScreen> createState() => _NpAnchorScreenState();
}

class _NpAnchorScreenState extends State<NpAnchorScreen> {
  String? _selectedAnchor;
  DateTime? _selectedDate;

  final Map<String, int> _intervals = {
    "Shot day": 7,
    "New pill pack": 28,
    "New patch or ring": 28,
    "A day of my own": 30,
  };

  final Map<String, String> _subtitles = {
    "Shot day": "e.g. testosterone or another injection",
    "New pill pack": "the first pill of each pack",
    "New patch or ring": "when you change it",
    "A day of my own": "name your own recurring marker",
  };

  final Map<String, IconData> _icons = {
    "Shot day": Icons.vaccines_outlined,
    "New pill pack": Icons.medication_outlined,
    "New patch or ring": Icons.album_outlined,
    "A day of my own": Icons.star_border,
  };

  void _selectAnchor(String anchor) {
    setState(() {
      if (_selectedAnchor == anchor) {
        _selectedAnchor = null;
        _selectedDate = null;
      } else {
        _selectedAnchor = anchor;
        _selectedDate = null; // Reset date on new anchor
      }
    });
  }

  Future<void> _pickDate() async {
    final now = AppClock.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now.subtract(const Duration(days: 300)),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: ThemeData.light().copyWith(
            colorScheme: const ColorScheme.light(
              primary: CircaColors.clay,
              onPrimary: Colors.white,
              surface: CircaColors.bg,
              onSurface: CircaColors.ink,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() => _selectedDate = picked);
    }
  }

  void _onContinue() {
    Map<String, dynamic>? anchorData;
    if (_selectedAnchor != null && _selectedDate != null) {
      anchorData = {
        'type': _selectedAnchor,
        'date': _selectedDate!.toIso8601String(),
        'interval': _intervals[_selectedAnchor!],
      };
    }

    final newData = widget.data.copyWith(anchor: anchorData);
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => NpSymptomsScreen(data: newData)),
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
                    Text("Want to anchor your cycle to a day?", style: CircaColors.title),
                    const SizedBox(height: 12),
                    Text(
                      "Without a period, an anchor gives your charts meaning. Pick what fits, or skip.",
                      style: CircaColors.helpText,
                    ),
                    const SizedBox(height: 32),
                    
                    ..._intervals.keys.map((anchor) => _buildAnchorOption(anchor)),
                    
                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
              child: CircaButton(
                label: (_selectedAnchor != null && _selectedDate != null) ? "Continue" : "Skip for now",
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
            color: index <= 1 ? CircaColors.clay : CircaColors.line,
            borderRadius: BorderRadius.circular(2),
          ),
        );
      }),
    );
  }

  Widget _buildAnchorOption(String anchor) {
    final isSelected = _selectedAnchor == anchor;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Column(
        children: [
          GestureDetector(
            onTap: () => _selectAnchor(anchor),
            child: Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: isSelected ? CircaColors.accentSoft : CircaColors.paper,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(
                  color: isSelected ? CircaColors.accentDeep : CircaColors.line, 
                  width: 1.5,
                ),
              ),
              child: Row(
                children: [
                  Icon(_icons[anchor], color: isSelected ? CircaColors.accentDeep : CircaColors.ink, size: 28),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          anchor, 
                          style: TextStyle(
                            fontSize: 16, 
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w600, 
                            color: isSelected ? CircaColors.accentDeep : CircaColors.ink,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          _subtitles[anchor]!, 
                          style: CircaColors.helpText.copyWith(
                            color: isSelected ? CircaColors.accentDeep.withOpacity(0.8) : CircaColors.muted,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            child: isSelected 
                ? Padding(
                    padding: const EdgeInsets.only(top: 16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text("MOST RECENT ${anchor.toUpperCase()}", style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: CircaColors.muted,
                          letterSpacing: 0.5,
                        )),
                        const SizedBox(height: 8),
                        GestureDetector(
                          onTap: _pickDate,
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                            decoration: BoxDecoration(
                              color: CircaColors.paper,
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(color: CircaColors.line, width: 1.5),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  _selectedDate != null 
                                      ? DateFormat.yMMMMd().format(_selectedDate!)
                                      : "Select a date",
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: _selectedDate != null ? CircaColors.ink : CircaColors.muted,
                                  ),
                                ),
                                const Icon(Icons.calendar_today_outlined, color: CircaColors.ink, size: 20),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }
}
