import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/cupertino.dart';
import 'package:intl/intl.dart';
import 'package:flutter_dynamic_icon/flutter_dynamic_icon.dart';
import 'stealth_mode_screen.dart';
import '../../theme/colors.dart';
import '../../models/cycle_profile.dart';
import '../../models/tracking_track.dart';
import '../../services/storage_service.dart';
import '../../utils/route_resolver.dart';
import '../common/components.dart';
import '../onboarding/intro_screen.dart';
import 'package:circa_app/utils/app_clock.dart';

class SettingsScreen extends StatefulWidget {
  final StorageService storage;

  const SettingsScreen({super.key, required this.storage});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  // Reminders
  late bool _remindNextPeriod;
  late bool _remindFertileWindow;
  late bool _remindMedications;
  late bool _remindAppointments;

  bool _appLockEnabled = false;
  String? _discreetIconName;

  // Pregnancy section
  bool _isPregnantMode = false;
  bool _endPregnancyToggled = false;
  String _pregnantCountFrom = 'Last period';
  DateTime? _pregnantDate;

  @override
  void initState() {
    super.initState();
    _appLockEnabled = widget.storage.appLockEnabled;
    _discreetIconName = widget.storage.discreetIconName;
    _remindNextPeriod = widget.storage.getSetting('remindNextPeriod', defaultValue: true);
    _remindFertileWindow = widget.storage.getSetting('remindFertileWindow', defaultValue: true);
    _remindMedications = widget.storage.getSetting('remindMedications', defaultValue: false);
    _remindAppointments = widget.storage.getSetting('remindAppointments', defaultValue: false);
  }

  void _saveSetting(String key, dynamic value) {
    widget.storage.saveSetting(key, value);
  }

  Future<void> _pickPregnantDate() async {
    final now = AppClock.now();
    final picked = await showDatePicker(
      context: context,
      initialDate: _pregnantDate ?? now,
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
      setState(() => _pregnantDate = picked);
    }
  }

  void _switchToPregnancy() async {
    if (_pregnantDate == null) return;
    
    final profile = widget.storage.profile;
    if (profile == null) return;

    DateTime lastPeriod;
    if (_pregnantCountFrom == 'Conception date') {
      lastPeriod = _pregnantDate!.subtract(const Duration(days: 14));
    } else {
      lastPeriod = _pregnantDate!;
    }

    final updated = profile.copyWith(isPregnant: true, lastPeriod: lastPeriod);
    await widget.storage.saveProfile(updated);
    
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => resolveHome(widget.storage.profile)),
        (route) => false,
      );
    }
  }

  void _setPostpartum() async {
    final profile = widget.storage.profile;
    if (profile == null) return;
    await widget.storage.saveProfile(profile.copyWith(mode: 'postpartum', isPregnant: false));
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => resolveHome(widget.storage.profile)),
        (route) => false,
      );
    }
  }

  void _setRecovery() async {
    final profile = widget.storage.profile;
    if (profile == null) return;
    await widget.storage.saveProfile(profile.copyWith(mode: 'recovery', isPregnant: false));
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => resolveHome(widget.storage.profile)),
        (route) => false,
      );
    }
  }

  void _resumeCycleTracking() async {
    final profile = widget.storage.profile;
    if (profile == null) return;
    
    final updated = CycleProfile(
      track: profile.track,
      lastPeriod: profile.lastPeriod,
      cycleLengthInDays: profile.cycleLengthInDays,
      isFertile: profile.isFertile,
      isPregnant: false,
      hormones: profile.hormones,
      anchor: profile.anchor,
      symptomsToTrack: profile.symptomsToTrack,
      trackMeds: profile.trackMeds,
      mode: null,
    );
    
    await widget.storage.saveProfile(updated);
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => resolveHome(widget.storage.profile)),
        (route) => false,
      );
    }
  }

  Future<void> _showDeleteDialog() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          backgroundColor: CircaColors.bg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          title: const Text("Delete everything?", style: TextStyle(fontWeight: FontWeight.w600, color: CircaColors.ink)),
          content: const Text(
            "This permanently erases all your logs, cycles, medications and settings from this device. It can't be undone.",
            style: TextStyle(color: CircaColors.muted),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context, false),
              child: const Text("Cancel", style: TextStyle(color: CircaColors.ink, fontWeight: FontWeight.w600)),
            ),
            TextButton(
              onPressed: () => Navigator.pop(context, true),
              child: const Text("Delete everything", style: TextStyle(color: Colors.redAccent, fontWeight: FontWeight.w600)),
            ),
          ],
        );
      },
    );

    if (result == true) {
      await widget.storage.clearAllData();
      if (mounted) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const IntroScreen()),
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final profile = widget.storage.profile;
    final showFertile = profile?.isFertile ?? true;
    final isAlreadyPregnant = profile?.isPregnant ?? false;

    return Scaffold(
      backgroundColor: CircaColors.bg,
      appBar: AppBar(
        backgroundColor: CircaColors.bg,
        elevation: 0,
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1.5),
          child: Container(color: CircaColors.line, height: 1.5),
        ),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: CircaColors.ink),
          onPressed: () => Navigator.pop(context),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircaLogo(size: 17),
            const SizedBox(width: 8),
            const Text(
              "Settings",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: CircaColors.ink),
            ),
          ],
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // REMINDERS
            Text("REMINDERS", style: CircaColors.eyebrow),
            const SizedBox(height: 12),
            _buildToggleRow("Next period", _remindNextPeriod, (v) {
              setState(() => _remindNextPeriod = v);
              _saveSetting('remindNextPeriod', v);
            }),
            if (showFertile)
              _buildToggleRow("Fertile window", _remindFertileWindow, (v) {
                setState(() => _remindFertileWindow = v);
                _saveSetting('remindFertileWindow', v);
              }),
            _buildToggleRow("Medications", _remindMedications, (v) {
              setState(() => _remindMedications = v);
              _saveSetting('remindMedications', v);
            }),
            _buildToggleRow("Appointments", _remindAppointments, (v) {
              setState(() => _remindAppointments = v);
              _saveSetting('remindAppointments', v);
            }, isLast: true),

            // PRIVACY
            const SizedBox(height: 32),
            Text("PRIVACY", style: CircaColors.eyebrow),
            const SizedBox(height: 12),
            _buildToggleRow("App Lock / Passcode", _appLockEnabled, (v) async {
              setState(() => _appLockEnabled = v);
              await widget.storage.setAppLockEnabled(v);
            }),
            const SizedBox(height: 12),
            Text("Privacy & Discretion", style: CircaColors.eyebrow),
            const SizedBox(height: 12),
            Material(
              color: CircaColors.paper,
              borderRadius: BorderRadius.circular(16),
              clipBehavior: Clip.antiAlias,
              child: ListTile(
                leading: const Icon(Icons.shield_outlined, color: CircaColors.accent),
                title: const Text("Stealth Mode Settings", style: TextStyle(fontWeight: FontWeight.w500)),
                trailing: const Icon(Icons.chevron_right, color: CircaColors.muted),
                onTap: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => StealthModeScreen(storage: widget.storage),
                    ),
                  );
                },
              ),
            ),
            const SizedBox(height: 32),
            
            // Backup
            Text("Data Backup", style: CircaColors.eyebrow),
            const SizedBox(height: 12),
            
            Builder(
              builder: (context) {
                final isPostpartumOrRecovery = profile?.mode == 'postpartum' || profile?.mode == 'recovery';
                
                if (isPostpartumOrRecovery) {
                  return Column(
                    children: [
                      _buildActionRow("Resume cycle tracking", _resumeCycleTracking, isLast: false),
                      _buildToggleRow("Start pregnancy tracking", _isPregnantMode, (v) {
                        setState(() => _isPregnantMode = v);
                      }, isLast: !_isPregnantMode),
                      if (_isPregnantMode) _buildPregnancyForm(),
                    ],
                  );
                } else if (isAlreadyPregnant) {
                  return Column(
                    children: [
                      _buildToggleRow("End pregnancy", _endPregnancyToggled, (v) {
                        setState(() => _endPregnancyToggled = v);
                      }, isLast: !_endPregnancyToggled),
                      if (_endPregnancyToggled) ...[
                        const SizedBox(height: 16),
                        CircaChoiceCard(
                          icon: Icons.child_care,
                          title: "My baby arrived!",
                          subtitle: "Congratulations. We'll move you into gentle postpartum tracking",
                          onTap: _setPostpartum,
                        ),
                        const SizedBox(height: 12),
                        CircaChoiceCard(
                          icon: Icons.favorite_border,
                          title: "I'm no longer pregnant",
                          subtitle: "We'll switch to a calm recovery mode, at your pace",
                          onTap: _setRecovery,
                        ),
                      ],
                    ],
                  );
                } else {
                  return Column(
                    children: [
                      _buildToggleRow("Start pregnancy tracking", _isPregnantMode, (v) {
                        setState(() => _isPregnantMode = v);
                      }, isLast: !_isPregnantMode),
                      if (_isPregnantMode) _buildPregnancyForm(),
                    ],
                  );
                }
              }
            ),

            // YOUR DATA
            const SizedBox(height: 32),
            Text("YOUR DATA", style: CircaColors.eyebrow),
            const SizedBox(height: 12),
            _buildActionRow("Download all logs", () { /* Stub */ }),
            _buildActionRow("Restore from a backup", () { /* Stub */ }),
            _buildActionRow("Delete my data and start fresh", _showDeleteDialog, isDestructive: true, isLast: true),

            // HELP CIRCA GROW
            const SizedBox(height: 32),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: CircaColors.accentSoft,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: CircaColors.accentDeep.withValues(alpha: 0.3), width: 1.5),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Help Circa grow", style: TextStyle(fontWeight: FontWeight.w700, fontSize: 18, color: CircaColors.accentDeep)),
                  const SizedBox(height: 8),
                  Text(
                    "Circa is, and always will be, completely free. If you'd like to chip in, your donation funds new features, and we'll unlock extra colour themes for you as a thank-you.",
                    style: CircaColors.helpText.copyWith(color: CircaColors.accentDeep.withValues(alpha: 0.8)),
                  ),
                  const SizedBox(height: 16),
                  CircaButton(label: "Donate", onPressed: () {}),
                  const SizedBox(height: 12),
                  CircaButton(label: "Unlock colour themes", isGhost: true, onPressed: () {}),
                ],
              ),
            ),
            
            const SizedBox(height: 32),
            const Center(
              child: Text(
                "100% free, and always private.\nYour data stays on your device, only ever yours.",
                textAlign: TextAlign.center,
                style: TextStyle(color: CircaColors.muted, fontSize: 13, height: 1.4),
              ),
            ),
            const SizedBox(height: 32),
          ],
        ),
      ),
    );
  }

  Widget _buildPregnancyForm() {
    return Padding(
      padding: const EdgeInsets.only(top: 16.0),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: CircaColors.paper,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: CircaColors.line, width: 1.5),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Count from", style: TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: _buildSegmentButton("Last period", _pregnantCountFrom == 'Last period', () {
                        setState(() => _pregnantCountFrom = 'Last period');
                      }),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _buildSegmentButton("Conception date", _pregnantCountFrom == 'Conception date', () {
                        setState(() => _pregnantCountFrom = 'Conception date');
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                GestureDetector(
                  onTap: _pickPregnantDate,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    decoration: BoxDecoration(
                      color: CircaColors.bg,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: CircaColors.line),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          _pregnantDate != null ? DateFormat.yMMMMd().format(_pregnantDate!) : "Select date",
                          style: TextStyle(color: _pregnantDate != null ? CircaColors.ink : CircaColors.muted),
                        ),
                        const Icon(Icons.calendar_today_outlined, size: 20, color: CircaColors.ink),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                CircaButton(
                  label: "Switch to pregnancy mode",
                  onPressed: _pregnantDate != null ? _switchToPregnancy : null,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildToggleRow(String label, bool value, ValueChanged<bool> onChanged, {String? sub, bool isLast = false}) {
    return Container(
      margin: EdgeInsets.only(bottom: isLast ? 0 : 8),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      decoration: BoxDecoration(
        color: CircaColors.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CircaColors.line, width: 1.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 16, color: CircaColors.ink)),
                if (sub != null) ...[
                  const SizedBox(height: 2),
                  Text(sub, style: const TextStyle(color: CircaColors.muted, fontSize: 14)),
                ],
              ],
            ),
          ),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: Colors.white,
            activeTrackColor: CircaColors.clay,
            inactiveThumbColor: CircaColors.muted,
            inactiveTrackColor: CircaColors.line,
          ),
        ],
      ),
    );
  }

  Widget _buildActionRow(String title, VoidCallback onTap, {bool isDestructive = false, bool isLast = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: EdgeInsets.only(bottom: isLast ? 0 : 8),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
        decoration: BoxDecoration(
          color: isDestructive ? const Color(0xFFFFF0F0) : CircaColors.paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isDestructive ? Colors.redAccent.withValues(alpha: 0.3) : CircaColors.line, width: 1.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(
              title, 
              style: TextStyle(
                fontWeight: FontWeight.w500, 
                fontSize: 16, 
                color: isDestructive ? Colors.redAccent : CircaColors.ink,
              ),
            ),
            Icon(Icons.arrow_forward_ios, size: 16, color: isDestructive ? Colors.redAccent : CircaColors.muted),
          ],
        ),
      ),
    );
  }

  Widget _buildSegmentButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: isSelected ? CircaColors.accentSoft : CircaColors.paper,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isSelected ? CircaColors.accent : CircaColors.line),
        ),
        alignment: Alignment.center,
        child: Text(
          label,
          style: TextStyle(
            fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
            color: isSelected ? CircaColors.accentDeep : CircaColors.ink,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}
