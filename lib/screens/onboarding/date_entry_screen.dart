import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/colors.dart';
import '../../models/onboarding_data.dart';
import '../common/components.dart';
import 'fertile_opt_in_screen.dart';
import '../track/forgot_period_screen.dart';
import 'package:circa_app/utils/app_clock.dart';

class DateEntryScreen extends StatefulWidget {
  final OnboardingData data;

  const DateEntryScreen({super.key, required this.data});

  @override
  State<DateEntryScreen> createState() => _DateEntryScreenState();
}

class _DateEntryScreenState extends State<DateEntryScreen> {
  DateTime? _selectedDate;

  @override
  void initState() {
    super.initState();
    _selectedDate = widget.data.lastPeriod;
  }

  Future<void> _pickDate() async {
    final now = AppClock.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _selectedDate ?? now,
      firstDate: now.subtract(const Duration(days: 365)),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: CircaColors.accent,
              onPrimary: CircaColors.paper,
              onSurface: CircaColors.ink,
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked != null) {
      setState(() {
        _selectedDate = picked;
      });
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
              Text("FINDING YOUR RHYTHM", style: CircaColors.eyebrow),
              const SizedBox(height: 12),
              Text("When did your last period start?", style: CircaColors.title),
              const SizedBox(height: 12),
              Text(
                "Just the first day of your most recent period; your best guess is fine.",
                style: CircaColors.helpText,
              ),
              const SizedBox(height: 32),
              
              // Date Field
              GestureDetector(
                onTap: _pickDate,
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                  decoration: BoxDecoration(
                    color: CircaColors.paper,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: CircaColors.line, width: 1.5),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "FIRST DAY OF LAST PERIOD",
                        style: CircaColors.eyebrow.copyWith(
                          color: CircaColors.muted,
                          fontSize: 10,
                          letterSpacing: 1.0,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        _selectedDate == null 
                            ? "Select a date" 
                            : DateFormat.yMMMMd().format(_selectedDate!),
                        style: TextStyle(
                          fontSize: 16,
                          color: _selectedDate == null ? CircaColors.muted : CircaColors.ink,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              
              const Spacer(),
              
              CircaButton(
                label: "Continue",
                onPressed: _selectedDate == null ? null : () {
                  final newData = widget.data.copyWith(lastPeriod: _selectedDate);
                  Navigator.of(context).push(
                    MaterialPageRoute(builder: (_) => FertileOptInScreen(data: newData)),
                  );
                },
              ),
              const SizedBox(height: 16),
              Center(
                child: GestureDetector(
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ForgotPeriodScreen(data: widget.data)),
                    );
                  },
                  child: Text(
                    "Can't remember your last period? →",
                    style: CircaColors.helpText.copyWith(
                      color: CircaColors.muted,
                      decoration: TextDecoration.underline,
                      decorationStyle: TextDecorationStyle.dashed,
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
