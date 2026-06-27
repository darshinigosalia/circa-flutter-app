import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../theme/colors.dart';
import '../models/onboarding_data.dart';
import '../services/storage_service.dart';
import '../utils/cycle_math.dart';
import 'components.dart';
import 'track_hub_screen.dart';
import 'charts_screen.dart';
import 'circa_drawer.dart';
import 'package:circa_app/utils/app_clock.dart';

class CycleHomeScreen extends StatefulWidget {
  final OnboardingData data;
  final StorageService storage;

  const CycleHomeScreen({
    super.key,
    required this.data,
    required this.storage,
  });

  @override
  State<CycleHomeScreen> createState() => _CycleHomeScreenState();
}

class _CycleHomeScreenState extends State<CycleHomeScreen> {
  late DateTime _displayMonth;
  bool _showYearPicker = false;

  @override
  void initState() {
    super.initState();
    final now = AppClock.now();
    _displayMonth = DateTime(now.year, now.month, 1);
  }

  void _changeMonth(int delta) {
    setState(() {
      _displayMonth = DateTime(_displayMonth.year, _displayMonth.month + delta, 1);
      _showYearPicker = false;
    });
  }

  void _setYear(int year) {
    setState(() {
      _displayMonth = DateTime(year, _displayMonth.month, 1);
      _showYearPicker = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.storage,
      builder: (context, _) {
        final lmp = widget.storage.mostRecentPeriodStart ?? widget.storage.profile?.lastPeriod ?? widget.data.lastPeriod;
        if (lmp == null) {
          // Fallback if somehow reached without a date
          return const Scaffold(body: Center(child: Text("No cycle data found.")));
        }
        
        final today = DateTime(AppClock.now().year, AppClock.now().month, AppClock.now().day);
        final cycleLength = 28; // Default, will refine later
        
        final dayInCycle = CycleMath.getDayInCycle(lmp, today, cycleLength);
        final phase = CycleMath.getPhase(dayInCycle, cycleLength);
        final nextPeriod = CycleMath.getNextPeriod(lmp, today, cycleLength);
        final isFertile = widget.data.fertile == true && widget.storage.getSetting('remindFertileWindow', defaultValue: true) == true;
        final ovDayOffset = CycleMath.getOvulationDay(cycleLength) - 1;
        final ovDate = lmp.add(Duration(days: ovDayOffset));
        
        final angle = ((dayInCycle - 1) / cycleLength) * 360;

        return Scaffold(
          backgroundColor: CircaColors.bg,
          drawer: CircaDrawer(storage: widget.storage, activeRoute: 'Home'),
          appBar: _buildAppBar(angle),
          body: Column(
            children: [
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Header
                      Text("CYCLE DAY $dayInCycle", style: CircaColors.eyebrow),
                      const SizedBox(height: 8),
                      Text("${phase.name} phase", style: CircaColors.title),
                      const SizedBox(height: 6),
                      Text(phase.note, style: CircaColors.helpText),
                      const SizedBox(height: 32),
                      
                      // Calendar Header
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          IconButton(
                            icon: const Icon(Icons.chevron_left, color: CircaColors.ink),
                            onPressed: () => _changeMonth(-1),
                          ),
                          TextButton(
                            onPressed: () => setState(() => _showYearPicker = !_showYearPicker),
                            child: Text(
                              DateFormat.yMMMM().format(_displayMonth),
                              style: const TextStyle(
                                fontSize: 18, 
                                fontWeight: FontWeight.w600, 
                                color: CircaColors.ink,
                              ),
                            ),
                          ),
                          IconButton(
                            icon: const Icon(Icons.chevron_right, color: CircaColors.ink),
                            onPressed: () => _changeMonth(1),
                          ),
                        ],
                      ),
                      
                      // Year Picker
                      if (_showYearPicker) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          height: 40,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: 6,
                            itemBuilder: (context, index) {
                              final y = today.year - 4 + index;
                              final isSelected = y == _displayMonth.year;
                              return GestureDetector(
                                onTap: () => _setYear(y),
                                child: Container(
                                  margin: const EdgeInsets.only(right: 8),
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? CircaColors.apricot : CircaColors.paper,
                                    borderRadius: BorderRadius.circular(20),
                                    border: Border.all(
                                      color: isSelected ? CircaColors.clay : CircaColors.line,
                                      width: 1.5,
                                    ),
                                  ),
                                  child: Center(
                                    child: Text(
                                      "$y",
                                      style: TextStyle(
                                        color: isSelected ? CircaColors.clay : CircaColors.ink,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            },
                          ),
                        ),
                        const SizedBox(height: 16),
                      ],
                      
                      // Calendar Grid
                      _buildCalendarGrid(lmp, cycleLength, isFertile),
                      
                      const SizedBox(height: 16),
                      Center(
                        child: Text(
                          "Tap a day to log how it felt.",
                          textAlign: TextAlign.center,
                          style: CircaColors.helpText.copyWith(fontSize: 13),
                        ),
                      ),
                      
                      const SizedBox(height: 24),
                      // Legend
                      _buildLegend(isFertile),
                      
                      const SizedBox(height: 32),
                      
                      // Pills
                      Row(
                        children: [
                          Expanded(
                            child: _buildSummaryPill(
                              "NEXT PERIOD",
                              "~${DateFormat("MMM d").format(nextPeriod)}",
                              "in ${CycleMath.daysBetween(today, nextPeriod)} days",
                            ),
                          ),
                          if (isFertile) const SizedBox(width: 12),
                          if (isFertile)
                            Expanded(
                              child: _buildSummaryPill(
                                "FERTILE WINDOW",
                                "${DateFormat("MMM d").format(ovDate.subtract(const Duration(days: 3)))} – ${DateFormat("MMM d").format(ovDate.add(const Duration(days: 1)))}",
                                "$cycleLength day avg",
                              ),
                            ),
                        ],
                      ),
                      
                      const SizedBox(height: 24),
                      
                      // Refinement Note
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: CircaColors.paper,
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(color: CircaColors.line, width: 1.5),
                        ),
                        child: Text(
                          "These predictions use an average 28-day cycle/5 day period for now. Once we’ve seen 3 of your cycles, we’ll use the median of your lengths to sharpen your next-period date.",
                          style: CircaColors.helpText.copyWith(fontSize: 14),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
              
              // Bottom Action Bar
              Container(
                decoration: const BoxDecoration(
                  color: CircaColors.bg,
                  border: Border(top: BorderSide(color: CircaColors.line, width: 1.5)),
                ),
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
                child: SafeArea(
                  top: false,
                  child: Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: CircaButton(
                          label: "Track",
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(
                                builder: (_) => TrackHubScreen(
                                  date: today,
                                  storage: widget.storage,
                                  data: widget.data,
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        flex: 1,
                        child: CircaButton(
                          label: "Charts",
                          isGhost: true,
                          onPressed: () {
                            Navigator.of(context).push(
                              MaterialPageRoute(builder: (_) => ChartsScreen(storage: widget.storage)),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        );
      }
    );
  }

  PreferredSizeWidget _buildAppBar(double angle) {
    return AppBar(
      backgroundColor: CircaColors.bg,
      elevation: 0,
      centerTitle: true,
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(1.5),
        child: Container(color: CircaColors.line, height: 1.5),
      ),
      leading: Builder(
        builder: (context) => IconButton(
          icon: const Icon(Icons.menu, color: CircaColors.ink),
          onPressed: () => Scaffold.of(context).openDrawer(),
        ),
      ),
      title: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          CircaLogo(size: 17, angle: angle),
          const SizedBox(width: 8),
          const Text(
            "Today",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: CircaColors.ink),
          ),
        ],
      ),
      actions: const [
        SizedBox(width: 48),
      ],
    );
  }

  Widget _buildSummaryPill(String eyebrow, String title, String sub) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: CircaColors.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CircaColors.line, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(eyebrow, style: CircaColors.eyebrow),
          const SizedBox(height: 8),
          Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16)),
          const SizedBox(height: 2),
          Text(sub, style: CircaColors.helpText.copyWith(fontSize: 14)),
        ],
      ),
    );
  }

  Widget _buildCalendarGrid(DateTime lmp, int cycleLength, bool isFertile) {
    final daysInMonth = DateTime(_displayMonth.year, _displayMonth.month + 1, 0).day;
    final firstWeekday = DateTime(_displayMonth.year, _displayMonth.month, 1).weekday;
    // Weekday is 1-7 (Mon-Sun). We want Sun-Sat (0-6).
    final startOffset = firstWeekday == 7 ? 0 : firstWeekday;

    final today = DateTime(AppClock.now().year, AppClock.now().month, AppClock.now().day);
    final allLogs = widget.storage.getAllLogs();

    return Column(
      children: [
        // Weekdays Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ["S", "M", "T", "W", "T", "F", "S"].map((d) {
            return SizedBox(
              width: 32,
              child: Center(
                child: Text(
                  d,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: CircaColors.muted,
                  ),
                ),
              ),
            );
          }).toList(),
        ),
        const SizedBox(height: 12),
        // Grid
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 7,
            mainAxisSpacing: 12,
            crossAxisSpacing: 12,
          ),
          itemCount: startOffset + daysInMonth,
          itemBuilder: (context, index) {
            if (index < startOffset) return const SizedBox.shrink();
            
            final day = index - startOffset + 1;
            final date = DateTime(_displayMonth.year, _displayMonth.month, day);
            
            final isFuture = date.isAfter(today);
            final isToday = date.isAtSameMomentAs(today);
            
            final isRecordedPeriod = CycleMath.isRecordedPeriodDay(date, allLogs);
            final isPredicted = CycleMath.isPredictedPeriod(date, lmp, cycleLength);
            final fertile = isFertile && CycleMath.isFertileWindow(date, lmp, cycleLength);
            final ovulation = isFertile && CycleMath.isOvulationDay(date, lmp, cycleLength);

            return Opacity(
              opacity: isFuture ? 0.55 : 1.0,
              child: GestureDetector(
                onTap: isFuture ? null : () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (_) => TrackHubScreen(
                        date: date,
                        storage: widget.storage,
                        data: widget.data,
                      ),
                    ),
                  );
                },
                child: Container(
                  decoration: BoxDecoration(
                    color: _getCellColor(isRecordedPeriod, isPredicted, fertile),
                    shape: BoxShape.circle,
                    border: _getCellBorder(isRecordedPeriod, isPredicted, ovulation, isToday),
                  ),
                  child: Center(
                    child: Text(
                      "$day",
                      style: TextStyle(
                        fontWeight: (isRecordedPeriod || isToday) ? FontWeight.w700 : FontWeight.w500,
                        color: _getTextColor(isRecordedPeriod, isPredicted, fertile, isToday),
                      ),
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ],
    );
  }

  Color _getCellColor(bool recorded, bool predicted, bool fertile) {
    if (recorded) return CircaColors.clay;
    if (predicted) return CircaColors.apricot;
    if (fertile) return CircaColors.accentSoft;
    return Colors.transparent;
  }

  BoxBorder? _getCellBorder(bool recorded, bool predicted, bool ovulation, bool isToday) {
    // Using a CustomPainter or stack is better for multiple borders, but we approximate:
    if (isToday) {
      return Border.all(color: CircaColors.ink, width: 2);
    }
    
    if (ovulation) {
      // 2px INSET ring in deep green (#37534A)
      return Border.all(color: CircaColors.accentDeep, width: 2);
    }
    
    // Dart doesn't natively support dashed borders easily in BoxDecoration.
    // For wireframe accuracy without an external package, we'll use a solid thin border for predicted
    // Or we could use a custom painter if STRICTLY required, but a 1.5px solid #C98A5E is an okay fallback
    if (predicted && !recorded) {
      return Border.all(color: const Color(0xFFC98A5E), width: 1.5); // Ideally dashed
    }

    return null;
  }

  Color _getTextColor(bool recorded, bool predicted, bool fertile, bool isToday) {
    if (recorded) return Colors.white;
    if (predicted) return CircaColors.clay;
    if (fertile) return CircaColors.accentDeep;
    if (isToday) return CircaColors.ink;
    return CircaColors.ink;
  }

  Widget _buildLegend(bool isFertile) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        _legendItem("Period", CircaColors.clay, null),
        const SizedBox(width: 16),
        _legendItem("Predicted", CircaColors.apricot, Border.all(color: const Color(0xFFC98A5E), width: 1.5)),
        if (isFertile) ...[
          const SizedBox(width: 16),
          _legendItem("Fertile", CircaColors.accentSoft, null),
          const SizedBox(width: 16),
          _legendItem("Ovulation", CircaColors.accentSoft, Border.all(color: CircaColors.accentDeep, width: 2)),
        ],
      ],
    );
  }

  Widget _legendItem(String label, Color fill, BoxBorder? border) {
    return Row(
      children: [
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: fill,
            shape: BoxShape.circle,
            border: border,
          ),
        ),
        const SizedBox(width: 6),
        Text(label, style: CircaColors.helpText.copyWith(fontSize: 12)),
      ],
    );
  }
}
