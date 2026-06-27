import re

with open("lib/screens/charts_symptoms_tab.dart", "r") as f:
    content = f.read()

# Replace _initToggles
new_init_toggles = """  void _initToggles() {
    final profile = widget.storage.profile;
    final allLogs = widget.storage.getLogs();
    final isNoPeriods = profile?.track == 'noperiods' && profile?.pregnant != true;
    
    // Base toggles
    _toggles = {
      if (!isNoPeriods) 'Bleeding': true,
      'Cramps': false,
      'Fatigue': false,
      'Mood': false,
      'Sleep': false,
      'Libido': false,
      'Basal Body Temp': false,
    };
    
    // Dynamically add all logged custom symptoms
    for (var log in allLogs) {
      for (var k in log.symptoms.keys) {
        if (!_toggles.containsKey(k)) _toggles[k] = false;
      }
      for (var c in log.customSymptoms) {
        if (!_toggles.containsKey(c.name)) _toggles[c.name] = false;
      }
    }
  }"""
content = re.sub(r'  void _initToggles\(\) \{[\s\S]*?    \}\n  \}', new_init_toggles, content)

# Replace _mapLogsToSeries mapping logic
old_map = """          if (metric == 'Bleeding' && log.bleedingFlowLevel != null) val = _mapBleeding(log.bleedingFlowLevel).toDouble();
          else if (metric == 'Cramps' && log.symptoms['Cramps'] != null) val = _mapSeverity(log.symptoms['Cramps']).toDouble();
          else if (metric == 'Fatigue' && log.symptoms['Fatigue'] != null) val = _mapSeverity(log.symptoms['Fatigue']).toDouble();
          else if (metric == 'Sleep' && log.symptoms['Sleep'] != null) val = _mapSleep(log.symptoms['Sleep']).toDouble();
          else if (metric == 'Mood' && log.symptoms['Mood changes'] != null) val = _mapSeverity(log.symptoms['Mood changes']).toDouble();
          else if (metric == 'Libido' && log.symptoms['Libido'] != null) val = _mapDirection(log.symptoms['Libido']).toDouble();
          else if (log.symptoms[metric] != null) val = _mapSeverity(log.symptoms[metric]).toDouble(); // generic symptom"""

new_map = """          if (metric == 'Bleeding' && log.bleedingFlowLevel != null) val = _mapBleeding(log.bleedingFlowLevel).toDouble();
          else if (metric == 'Cramps' && log.symptoms['Cramps'] != null) val = _mapSeverity(log.symptoms['Cramps']).toDouble();
          else if (metric == 'Fatigue' && log.symptoms['Fatigue'] != null) val = _mapSeverity(log.symptoms['Fatigue']).toDouble();
          else if (metric == 'Sleep' && log.symptoms['Sleep'] != null) val = _mapSleep(log.symptoms['Sleep']).toDouble();
          else if (metric == 'Mood' && (log.symptoms['Mood changes'] != null || log.symptoms['Mood'] != null)) val = _mapSeverity(log.symptoms['Mood changes'] ?? log.symptoms['Mood']).toDouble();
          else if (metric == 'Libido' && log.symptoms['Libido'] != null) val = _mapDirection(log.symptoms['Libido']).toDouble();
          else if (metric == 'Basal Body Temp' && log.basalBodyTemperature != null) val = log.basalBodyTemperature;
          else if (log.symptoms[metric] != null) val = _mapSeverity(log.symptoms[metric]).toDouble();
          else if (log.customSymptoms.any((c) => c.name == metric)) val = 1.0;"""
content = content.replace(old_map, new_map)

# Replace build chart rendering
old_chart = """          // Chart
          SizedBox(
            height: 250,"""

# We'll just write a script to rewrite build()
