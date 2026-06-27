import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../services/storage_service.dart';
import '../../models/tracking_track.dart';
import '../../models/cycle_mode.dart';
import '../common/components.dart';
import 'charts_symptoms_tab.dart';
import 'charts_cycles_tab.dart';
import 'charts_medications_tab.dart';

class ChartsScreen extends StatefulWidget {
  final StorageService storage;

  const ChartsScreen({super.key, required this.storage});

  @override
  State<ChartsScreen> createState() => _ChartsScreenState();
}

class _ChartsScreenState extends State<ChartsScreen> {
  @override
  Widget build(BuildContext context) {
    final profile = widget.storage.profile;
    final isPregnant = profile?.isPregnant == true;
    final isPostpartumOrRecovery = profile?.mode == CycleMode.postpartum || profile?.mode == CycleMode.recovery;
    final isNoPeriods = profile?.track == TrackingTrack.noperiods && !isPregnant && !isPostpartumOrRecovery;
    final hasMeds = widget.storage.getAllMedications().isNotEmpty;

    List<Tab> tabs = [];
    List<Widget> views = [];

    if (isPregnant) {
      tabs = const [Tab(text: "Symptoms"), Tab(text: "Medications")];
      views = [ChartsSymptomsTab(storage: widget.storage), ChartsMedicationsTab(storage: widget.storage)];
    } else if (isNoPeriods || isPostpartumOrRecovery) {
      if (hasMeds || (profile?.trackMeds == true)) {
        tabs = const [Tab(text: "Symptoms"), Tab(text: "Medications")];
        views = [ChartsSymptomsTab(storage: widget.storage), ChartsMedicationsTab(storage: widget.storage)];
      } else {
        tabs = const [Tab(text: "Symptoms")];
        views = [ChartsSymptomsTab(storage: widget.storage)];
      }
    } else {
      tabs = const [Tab(text: "Symptoms"), Tab(text: "Cycles")];
      views = [ChartsSymptomsTab(storage: widget.storage), ChartsCyclesTab(storage: widget.storage)];
    }

    if (tabs.length == 1) {
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
                "Charts",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: CircaColors.ink),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.home_outlined, color: CircaColors.ink),
              onPressed: () => Navigator.of(context).popUntil((route) => route.isFirst),
            ),
          ],
        ),
        body: views[0],
      );
    }
        
    return DefaultTabController(
      length: tabs.length,
      child: Scaffold(
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
                "Charts",
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: CircaColors.ink),
              ),
            ],
          ),
          actions: [
            IconButton(
              icon: const Icon(Icons.home_outlined, color: CircaColors.ink),
              onPressed: () {
                Navigator.of(context).popUntil((route) => route.isFirst);
              },
            ),
          ],
          bottom: TabBar(
            labelColor: CircaColors.ink,
            unselectedLabelColor: CircaColors.muted,
            indicatorColor: CircaColors.clay,
            indicatorWeight: 3,
            labelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 16),
            tabs: tabs,
          ),
        ),
        body: TabBarView(
          children: views,
        ),
      ),
    );
  }
}
