import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/colors.dart';
import '../models/onboarding_data.dart';
import '../models/cycle_profile.dart';
import '../services/storage_service.dart';
import 'components.dart';
import 'forgot_period_screen.dart';
import '../utils/route_resolver.dart';
import 'package:circa_app/utils/app_clock.dart';

class GestationDateScreen extends StatefulWidget {
  final OnboardingData data;

  const GestationDateScreen({super.key, required this.data});

  @override
  State<GestationDateScreen> createState() => _GestationDateScreenState();
}

class _GestationDateScreenState extends State<GestationDateScreen> {
  DateTime? _selectedDate;

  void _pickDate() async {
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
              Text("ESTIMATING YOUR DUE DATE", style: CircaColors.eyebrow),
              const SizedBox(height: 12),
              Text("When did your last period start?", style: CircaColors.title),
              const SizedBox(height: 12),
              Text(
                "The first day of your last period helps us estimate how far along you are.",
                style: CircaColors.helpText,
              ),
              const SizedBox(height: 40),
              
              const Text("FIRST DAY OF LAST PERIOD", style: TextStyle(
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
              
              const Spacer(),
              
              CircaButton(
                label: "Continue",
                onPressed: _selectedDate == null ? null : () async {
                  final storage = storageService;
                  // Await saving to hive
                  final profile = CycleProfile(
                    track: widget.data.track ?? 'noperiods',
                    pregnant: widget.data.pregnant ?? true,
                    lastPeriod: _selectedDate!,
                    fertile: widget.data.fertile ?? false,
                    cycleLength: 28,
                  );
                  await storage.saveProfile(profile);
                  
                  if (!context.mounted) return;
                  Navigator.of(context).pushAndRemoveUntil(
                    MaterialPageRoute(builder: (_) => resolveHome(storageService.profile)),
                    (route) => false,
                  );
                },
              ),
              const SizedBox(height: 16),
              Center(
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(builder: (_) => ForgotPeriodScreen(data: widget.data)),
                    );
                  },
                  child: const Text(
                    "Can't remember your last period? →",
                    style: TextStyle(
                      color: CircaColors.muted,
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }
}
