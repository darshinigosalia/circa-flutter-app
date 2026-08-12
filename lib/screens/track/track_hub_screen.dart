import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../theme/colors.dart';
import '../../models/onboarding_data.dart';
import '../../models/cycle_type.dart';
import '../../models/pregnancy_outcome.dart';
import '../../utils/route_resolver.dart';
import '../../models/day_log.dart';
import '../../services/storage_service.dart';
import '../../utils/cycle_math.dart';
import '../common/components.dart';
import 'symptoms_sub_screen.dart';
import 'package:circa_app/utils/app_clock.dart';

class TrackHubScreen extends StatefulWidget {
  final DateTime date;
  final StorageService storage;
  final OnboardingData data;
  final DayLog? initialDraft;

  const TrackHubScreen({
    super.key,
    required this.date,
    required this.storage,
    required this.data,
    this.initialDraft,
  });

  @override
  State<TrackHubScreen> createState() => _TrackHubScreenState();
}

class _TrackHubScreenState extends State<TrackHubScreen> {
  late DayLog _log;
  late DateTime _selectedDate;
  late ScrollController _dateScrollController;

  @override
  void initState() {
    super.initState();
    _selectedDate = DateTime(widget.date.year, widget.date.month, widget.date.day);
    _dateScrollController = ScrollController();

    if (widget.initialDraft != null) {
      _log = widget.initialDraft!;
    } else {
      final existing = widget.storage.getLogForDate(_selectedDate);
      if (existing != null) {
        _log = existing.copyWith();
      } else {
        _log = DayLog(date: _selectedDate, loggedAt: AppClock.now());
      }
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      _scrollToSelectedDate(animate: false);
    });
  }

  @override
  void dispose() {
    _dateScrollController.dispose();
    super.dispose();
  }

  void _openCalendarPicker() async {
    final today = DateTime(AppClock.now().year, AppClock.now().month, AppClock.now().day);
    final initial = _selectedDate.isAfter(today) ? today : _selectedDate;

    final picked = await showDatePicker(
      context: context,
      initialDate: initial,
      firstDate: DateTime(today.year - 2, 1, 1),
      lastDate: today,
      selectableDayPredicate: (d) => !DateTime(d.year, d.month, d.day).isAfter(today),
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: CircaColors.accent,
              onPrimary: Colors.white,
              surface: CircaColors.paper,
              onSurface: CircaColors.ink,
            ),
            dialogTheme: const DialogThemeData(backgroundColor: CircaColors.paper),
          ),
          child: child!,
        );
      },
    );

    if (picked != null && mounted) {
      final normPicked = DateTime(picked.year, picked.month, picked.day);
      if (normPicked.isAfter(today)) return;

      setState(() {
        _selectedDate = normPicked;
        final existing = widget.storage.getLogForDate(normPicked);
        if (existing != null) {
          _log = existing.copyWith();
        } else {
          _log = DayLog(date: normPicked, loggedAt: AppClock.now());
        }
      });
      _scrollToSelectedDate(animate: true);
    }
  }

  void _scrollToSelectedDate({bool animate = true}) {
    if (!_dateScrollController.hasClients) return;
    final today = DateTime(AppClock.now().year, AppClock.now().month, AppClock.now().day);
    final daysAgo = today.difference(_selectedDate).inDays;
    final totalDays = daysAgo > 180 ? daysAgo + 30 : 180;
    final selectedIndex = totalDays - daysAgo;

    const itemWidth = 54.0;
    final screenWidth = MediaQuery.of(context).size.width - 52.0;
    final targetOffset = (selectedIndex * itemWidth) - (screenWidth / 2) + (itemWidth / 2);
    final clampedOffset = targetOffset.clamp(0.0, _dateScrollController.position.maxScrollExtent);

    if (animate) {
      _dateScrollController.animateTo(
        clampedOffset,
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeOutCubic,
      );
    } else {
      _dateScrollController.jumpTo(clampedOffset);
    }
  }

  Widget _buildHorizontalDateStrip() {
    final today = DateTime(AppClock.now().year, AppClock.now().month, AppClock.now().day);
    final daysAgo = today.difference(_selectedDate).inDays;
    final totalDays = daysAgo > 180 ? daysAgo + 30 : 180;

    return SizedBox(
      height: 60,
      child: ListView.builder(
        controller: _dateScrollController,
        scrollDirection: Axis.horizontal,
        physics: const BouncingScrollPhysics(),
        itemCount: totalDays + 1,
        itemBuilder: (context, index) {
          final date = today.subtract(Duration(days: totalDays - index));
          final isSelected = date.year == _selectedDate.year &&
              date.month == _selectedDate.month &&
              date.day == _selectedDate.day;

          final dayStr = date.day.toString();
          final monthStr = DateFormat("MMM").format(date).toUpperCase();

          return GestureDetector(
            onTap: () {
              if (isSelected) return;
              setState(() {
                _selectedDate = date;
                final existing = widget.storage.getLogForDate(date);
                if (existing != null) {
                  _log = existing.copyWith();
                } else {
                  _log = DayLog(date: date, loggedAt: AppClock.now());
                }
              });
              _scrollToSelectedDate(animate: true);
            },
            child: Container(
              width: 46,
              height: 46,
              margin: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: CircaColors.paper,
                border: Border.all(
                  color: isSelected ? CircaColors.accent : CircaColors.line,
                  width: isSelected ? 2.5 : 1.0,
                ),
              ),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(
                    dayStr,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: isSelected ? CircaColors.ink : CircaColors.ink.withValues(alpha: 0.8),
                      height: 1.0,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    monthStr,
                    style: TextStyle(
                      fontSize: 8.5,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.3,
                      color: isSelected ? CircaColors.accent : CircaColors.muted,
                      height: 1.0,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  void _saveLog() async {
    final toSave = _log.copyWith(
      loggedAt: AppClock.now(),
    );
    await widget.storage.saveLog(toSave);
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (_) => resolveHome(widget.storage.profile)),
        (route) => false,
      );
    }
  }

  int _countSymptoms() {
    int count = 0;
    if (_log.bleedingFlowLevel != null) count++;
    if (_log.dischargeAmount != null) count++;
    count += _log.symptoms.length;
    count += _log.customSymptoms.length;
    if (_log.notes.isNotEmpty) count++;
    return count;
  }

  void _openSymptoms() async {
    final updatedDraft = await Navigator.of(context).push<DayLog>(
      MaterialPageRoute(builder: (_) => SymptomsSubScreen(draft: _log)),
    );
    if (updatedDraft != null && mounted) {
      setState(() {
        _log = updatedDraft;
      });
    }
  }

  void _openIntercourseSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: CircaColors.paper,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Log intercourse", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: CircaColors.ink)),
                const SizedBox(height: 24),
                _bottomSheetButton("With protection", () {
                  setState(() => _log = _log.copyWith(intercourseProtected: true));
                  Navigator.pop(context);
                }),
                const SizedBox(height: 12),
                _bottomSheetButton("Without protection", () {
                  setState(() => _log = _log.copyWith(intercourseProtected: false));
                  Navigator.pop(context);
                }),
                const SizedBox(height: 12),
                _bottomSheetButton("None", () {
                  setState(() => _log = _log.copyWith(intercourseProtected: null));
                  Navigator.pop(context);
                }, isGhost: true),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openContraceptionSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: CircaColors.paper,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (context) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 24, horizontal: 26),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text("Started contraception / IUD today", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: CircaColors.ink)),
                const SizedBox(height: 24),
                ...["Morning-after pill", "Monthly pill", "IUD", "Patch", "Implant"].map((opt) {
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 12),
                    child: _bottomSheetButton(opt, () {
                      setState(() => _log = _log.copyWith(contraceptionType: opt));
                      Navigator.pop(context);
                    }),
                  );
                }),
                _bottomSheetButton("None", () {
                  setState(() => _log = _log.copyWith(contraceptionType: null));
                  Navigator.pop(context);
                }, isGhost: true),
              ],
            ),
          ),
        );
      },
    );
  }

  void _openBBTSheet() {
    final TextEditingController controller = TextEditingController(
      text: _log.basalBodyTemperature?.toString() ?? '',
    );
    showModalBottomSheet(
      context: context,
      backgroundColor: CircaColors.paper,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      isScrollControlled: true,
      builder: (context) {
        return Padding(
          padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom,
            top: 24, left: 26, right: 26,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text("Basal Body Temperature", style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: CircaColors.ink)),
              const SizedBox(height: 16),
              TextField(
                controller: controller,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                decoration: const InputDecoration(
                  hintText: "e.g., 98.2 or 36.6",
                  border: OutlineInputBorder(),
                ),
                autofocus: true,
              ),
              const SizedBox(height: 24),
              _bottomSheetButton("Save", () {
                final val = double.tryParse(controller.text);
                setState(() => _log = _log.copyWith(basalBodyTemperature: val));
                Navigator.pop(context);
              }),
              const SizedBox(height: 12),
              _bottomSheetButton("Clear", () {
                setState(() => _log = _log.copyWith(basalBodyTemperature: null));
                Navigator.pop(context);
              }, isGhost: true),
              const SizedBox(height: 24),
            ],
          ),
        );
      },
    );
  }

  Widget _bottomSheetButton(String label, VoidCallback onTap, {bool isGhost = false}) {
    return SizedBox(
      width: double.infinity,
      child: CircaButton(
        label: label,
        isGhost: isGhost,
        onPressed: onTap,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final today = DateTime(AppClock.now().year, AppClock.now().month, AppClock.now().day);
    final normDate = DateTime(_selectedDate.year, _selectedDate.month, _selectedDate.day);
    final isToday = normDate.isAtSameMomentAs(today);

    final title = isToday ? "What would you like to log?" : "Logging for ${DateFormat("E, MMM d").format(_selectedDate)}";
    final saveText = isToday ? "Save today's log" : "Save this day's log";
    
    final symptomCount = _countSymptoms();

    // Show period buttons only for personas who bleed.
    final profile = widget.storage.profile;
    final showPeriodButtons = profile != null &&
        (profile.cycleType == CycleType.periods ||
         profile.pregnancyOutcome == PregnancyOutcome.postpartum ||
         profile.pregnancyOutcome == PregnancyOutcome.recovery);

    return Scaffold(
      backgroundColor: CircaColors.bg,
      appBar: AppBar(
        backgroundColor: CircaColors.bg,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: CircaColors.ink),
          onPressed: () => Navigator.pop(context),
        ),
        centerTitle: true,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const CircaLogo(size: 17),
            const SizedBox(width: 8),
            const Text(
              "Track",
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: CircaColors.ink),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.calendar_today_outlined, color: CircaColors.ink),
            onPressed: _openCalendarPicker,
          ),
          const SizedBox(width: 8),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildHorizontalDateStrip(),
                  const SizedBox(height: 16),
                  Text(title, style: CircaColors.title),
                  const SizedBox(height: 32),
                  
                  // Period Buttons — shown only for personas who bleed
                  if (showPeriodButtons) _buildPeriodButtons(),
                  if (showPeriodButtons) const SizedBox(height: 24),
                  
                  // Symptoms Row
                  _buildHubRow(
                    "Symptoms", 
                    symptomCount > 0 ? "$symptomCount logged" : "Log how you're feeling, add notes", 
                    _openSymptoms,
                    showChevron: true,
                    isActive: symptomCount > 0,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // BBT Row
                  _buildHubRow(
                    "Basal Body Temp", 
                    _log.basalBodyTemperature != null ? "${_log.basalBodyTemperature}°" : "Add temp", 
                    _openBBTSheet,
                    isActive: _log.basalBodyTemperature != null,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Intercourse Row
                  _buildHubRow(
                    "Log intercourse", 
                    _log.intercourseProtected != null 
                        ? (_log.intercourseProtected! ? "With protection" : "Without protection") 
                        : "None", 
                    _openIntercourseSheet,
                    isActive: _log.intercourseProtected != null,
                  ),
                  
                  const SizedBox(height: 12),
                  
                  // Contraception Row
                  _buildHubRow(
                    "Started contraception / IUD", 
                    _log.contraceptionType ?? "None", 
                    _openContraceptionSheet,
                    isActive: _log.contraceptionType != null,
                  ),
                ],
              ),
            ),
          ),
          
          // Save Button Bar
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
            decoration: const BoxDecoration(
              color: CircaColors.bg,
              border: Border(top: BorderSide(color: CircaColors.line, width: 1.5)),
            ),
            child: SafeArea(
              top: false,
              child: CircaButton(
                label: saveText,
                onPressed: _saveLog,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHubRow(String title, String subtitle, VoidCallback onTap, {bool showChevron = false, bool isActive = false}) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
        decoration: BoxDecoration(
          color: isActive ? CircaColors.apricot : CircaColors.paper,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: isActive ? CircaColors.clay : CircaColors.line, width: 1.5),
        ),
        child: Row(
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: TextStyle(fontWeight: FontWeight.w600, fontSize: 16, color: isActive ? CircaColors.clay : CircaColors.ink)),
                  const SizedBox(height: 4),
                  Text(subtitle, style: CircaColors.helpText.copyWith(fontSize: 13, color: isActive ? CircaColors.clay.withValues(alpha: 0.8) : CircaColors.muted)),
                ],
              ),
            ),
            if (showChevron) const Icon(Icons.arrow_forward_ios, size: 16, color: CircaColors.muted),
          ],
        ),
      ),
    );
  }

  Widget _buildPeriodButtons() {
    final lmp = widget.storage.mostRecentPeriodStart;
    final isPeriodKnownThisCycle = lmp != null && CycleMath.daysBetween(lmp, _selectedDate) >= 0 && CycleMath.daysBetween(lmp, _selectedDate) < 30;
    
    final startedLog = _log.periodStarted;
    final endedLog = _log.periodEnded;
    
    final disableStart = startedLog || (isPeriodKnownThisCycle && !startedLog);
    final disableEnd = endedLog;

    return Row(
      children: [
        Expanded(
          child: _periodBtn(
            "Period started",
            disableStart ? "already logged" : "tap to log",
            disableStart,
            () {
              setState(() => _log = _log.copyWith(periodStarted: true));
            },
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _periodBtn(
            "Period ended",
            disableEnd ? "already logged" : "tap to log",
            disableEnd,
            () {
              setState(() => _log = _log.copyWith(periodEnded: true));
            },
          ),
        ),
      ],
    );
  }

  Widget _periodBtn(String title, String sub, bool isLogged, VoidCallback onTap) {
    return GestureDetector(
      onTap: isLogged ? null : onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 12),
        decoration: BoxDecoration(
          color: isLogged ? CircaColors.apricot : CircaColors.accentSoft,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: isLogged ? CircaColors.clay : CircaColors.accent,
            width: 1.5,
          ),
        ),
        child: Column(
          children: [
            Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: isLogged ? CircaColors.clay : CircaColors.accentDeep,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              sub,
              textAlign: TextAlign.center,
              style: CircaColors.helpText.copyWith(
                fontSize: 12,
                color: isLogged ? CircaColors.clay.withValues(alpha: 0.8) : CircaColors.accentDeep.withValues(alpha: 0.8),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
