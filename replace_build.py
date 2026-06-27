import re

with open("lib/screens/charts_symptoms_tab.dart", "r") as f:
    content = f.read()

# I will replace from `  @override\n  Widget build(BuildContext context) {` to the end of the file.
new_build = """  @override
  Widget build(BuildContext context) {
    final allLogs = widget.storage.getLogs();
    final now = DateTime.now();

    // Insights
    final cycles = CycleExtractor.extractCycles(allLogs);
    final avgLength = CycleExtractor.calculatePredictedCycleLength(allLogs);
    int fatigueCount = 0;
    if (_scale == TimeScale.cycle && cycles.isNotEmpty) {
      for (final l in cycles.first.logs) {
        if (l.symptoms.containsKey('Fatigue')) fatigueCount++;
      }
    }

    double maxX = 30;
    if (_scale == TimeScale.yearly) maxX = 12;
    if (_scale == TimeScale.monthly) maxX = 31;
    if (_scale == TimeScale.cycle) maxX = (cycles.isNotEmpty && cycles.first.length != null) ? cycles.first.length!.toDouble() + 3 : 35;

    final selectedMetrics = _toggles.entries.where((e) => e.value).map((e) => e.key).toList();

    return SingleChildScrollView(
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Time Scale Segmented Control
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26),
            child: SegmentedButton<TimeScale>(
              segments: const [
                ButtonSegment(value: TimeScale.cycle, label: Text("Current Cycle")),
                ButtonSegment(value: TimeScale.monthly, label: Text("Monthly")),
                ButtonSegment(value: TimeScale.yearly, label: Text("Yearly")),
              ],
              selected: {_scale},
              onSelectionChanged: (set) {
                setState(() => _scale = set.first);
              },
              style: ButtonStyle(
                backgroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) return CircaColors.clay;
                  return CircaColors.paper;
                }),
                foregroundColor: WidgetStateProperty.resolveWith((states) {
                  if (states.contains(WidgetState.selected)) return Colors.white;
                  return CircaColors.ink;
                }),
              ),
            ),
          ),
          
          const SizedBox(height: 32),
          
          // Legend Toggles (Expandable)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 26),
            child: Theme(
              data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
              child: ExpansionTile(
                title: const Text("Select Symptoms to Track", style: TextStyle(fontWeight: FontWeight.w600, color: CircaColors.ink)),
                initiallyExpanded: false,
                tilePadding: EdgeInsets.zero,
                children: [
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: _toggles.entries.map((e) {
                      final metric = e.key;
                      final isOn = e.value;
                      return FilterChip(
                        label: Text(metric),
                        selected: isOn,
                        onSelected: (val) {
                          setState(() {
                            _toggles[metric] = val;
                          });
                        },
                        selectedColor: CircaColors.accentSoft,
                        checkmarkColor: CircaColors.accentDeep,
                        labelStyle: TextStyle(
                          color: isOn ? CircaColors.accentDeep : CircaColors.ink,
                          fontWeight: isOn ? FontWeight.w600 : FontWeight.w500,
                        ),
                        backgroundColor: CircaColors.paper,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(20),
                          side: BorderSide(color: isOn ? CircaColors.accent : CircaColors.line),
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Stacked Sparkline Charts
          if (selectedMetrics.isEmpty)
            const Center(
              child: Padding(
                padding: EdgeInsets.all(32.0),
                child: Text("Select a metric above", style: TextStyle(color: CircaColors.muted)),
              ),
            )
          else
            for (var metric in selectedMetrics)
              Padding(
                padding: const EdgeInsets.only(bottom: 24.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 26),
                      child: Text(metric, style: const TextStyle(fontWeight: FontWeight.w600, color: CircaColors.ink)),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 100, // Fixed small height for sparkline
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 16),
                        child: SizedBox(
                          width: maxX * 20.0 > MediaQuery.of(context).size.width ? maxX * 20.0 : MediaQuery.of(context).size.width - 32,
                          child: Builder(
                            builder: (context) {
                              final spots = _mapLogsToSeries(allLogs, metric, _scale, now);
                              if (spots.isEmpty) {
                                return const Center(child: Text("No data", style: TextStyle(color: CircaColors.line)));
                              }
                              
                              double minY = 0;
                              double maxY = 5;
                              if (metric == 'Basal Body Temp') {
                                minY = spots.map((e) => e.y).reduce((a, b) => a < b ? a : b) - 0.5;
                                maxY = spots.map((e) => e.y).reduce((a, b) => a > b ? a : b) + 0.5;
                              } else if (metric == 'Libido') {
                                minY = -2;
                                maxY = 2;
                              }
                              
                              return LineChart(
                                LineChartData(
                                  minX: 1,
                                  maxX: maxX,
                                  minY: minY,
                                  maxY: maxY,
                                  gridData: FlGridData(
                                    show: true,
                                    drawVerticalLine: false,
                                    getDrawingHorizontalLine: (value) => FlLine(color: CircaColors.line.withValues(alpha: 0.5), strokeWidth: 1),
                                  ),
                                  borderData: FlBorderData(show: false),
                                  titlesData: FlTitlesData(
                                    leftTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    rightTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    topTitles: AxisTitles(sideTitles: SideTitles(showTitles: false)),
                                    bottomTitles: AxisTitles(
                                      sideTitles: SideTitles(
                                        showTitles: true,
                                        interval: _scale == TimeScale.yearly ? 1 : 5,
                                        getTitlesWidget: (value, meta) {
                                          return Padding(
                                            padding: const EdgeInsets.only(top: 8),
                                            child: Text(
                                              value.toInt().toString(),
                                              style: const TextStyle(color: CircaColors.muted, fontSize: 10),
                                            ),
                                          );
                                        },
                                      ),
                                    ),
                                  ),
                                  lineBarsData: [
                                    LineChartBarData(
                                      spots: spots,
                                      isCurved: false,
                                      color: CircaColors.accent,
                                      barWidth: 2,
                                      dotData: FlDotData(
                                        show: true,
                                        getDotPainter: (spot, percent, barData, index) {
                                          return FlDotCirclePainter(
                                            radius: 3,
                                            color: CircaColors.accentDeep,
                                            strokeWidth: 0,
                                          );
                                        },
                                      ),
                                    ),
                                  ],
                                  lineTouchData: LineTouchData(
                                    touchTooltipData: LineTouchTooltipData(
                                      getTooltipItems: (touchedSpots) {
                                        return touchedSpots.map((spot) {
                                          return LineTooltipItem(
                                            metric == 'Basal Body Temp' ? spot.y.toStringAsFixed(1) : spot.y.toInt().toString(),
                                            const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
                                          );
                                        }).toList();
                                      },
                                    ),
                                  ),
                                ),
                              );
                            }
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
          
          const SizedBox(height: 32),
          
          // Insights
          if (avgLength > 0 || fatigueCount > 0)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 26),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text("INSIGHTS", style: CircaColors.eyebrow),
                  const SizedBox(height: 12),
                  if (avgLength > 0)
                    Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: CircaColors.paper,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: CircaColors.line),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.show_chart, color: CircaColors.clay),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text("Average cycle length: $avgLength days.", style: const TextStyle(fontSize: 15, color: CircaColors.ink)),
                          ),
                        ],
                      ),
                    ),
                  if (fatigueCount > 0 && _scale == TimeScale.cycle)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: CircaColors.paper,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: CircaColors.line),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.bolt, color: Colors.blueGrey),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text("You logged fatigue $fatigueCount times this cycle.", style: const TextStyle(fontSize: 15, color: CircaColors.ink)),
                          ),
                        ],
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
"""

match = re.search(r'  @override\n  Widget build\(BuildContext context\) \{', content)
if match:
    start_index = match.start()
    content = content[:start_index] + new_build
else:
    print("Could not find build method")

with open("lib/screens/charts_symptoms_tab.dart", "w") as f:
    f.write(content)
