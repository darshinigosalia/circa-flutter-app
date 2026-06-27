import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../models/day_log.dart';
import '../services/storage_service.dart';
import 'package:circa_app/utils/app_clock.dart';

class SymptomsSubScreen extends StatefulWidget {
  final DayLog draft;
  final String? preSelected;

  const SymptomsSubScreen({super.key, required this.draft, this.preSelected});

  /// Maps home-screen chip labels to the canonical symptom key used in
  /// [_standardSymptoms] (or the special token `_bleeding_flow` for the
  /// bleeding-flow toggle section).
  static const chipLabelToKey = <String, String>{
    'Mood': 'Mood changes',
    'Lochia (bleeding)': '_bleeding_flow',
    'Bleeding': '_bleeding_flow',
  };

  @override
  State<SymptomsSubScreen> createState() => _SymptomsSubScreenState();
}

class _SymptomsSubScreenState extends State<SymptomsSubScreen> {
  late DayLog _log;
  final TextEditingController _notesController = TextEditingController();
  final TextEditingController _customSymptomController = TextEditingController();

  bool _flowExpanded = false;
  bool _dischargeExpanded = false;
  final Map<String, bool> _symptomExpanded = {};

  final Map<String, List<String>> _standardSymptoms = {
    'Cramps': ['Mild', 'Moderate', 'Severe'],
    'Fatigue': ['Mild', 'Moderate', 'Severe'],
    'Headaches': ['Mild', 'Moderate', 'Severe'],
    'Bloating': ['Mild', 'Moderate', 'Severe'],
    'Breast tenderness': ['Mild', 'Moderate', 'Severe'],
    'Nausea': ['Mild', 'Moderate', 'Severe'],
    'Skin / acne': ['Mild', 'Moderate', 'Severe'],
    'Mood changes': ['Positive', 'Low', 'Irritable', 'Anxious'],
    'Sleep': ['Slept well', 'Restless', 'Poorly'],
    'Libido': ['Higher', 'Lower'],
    'Appetite': ['Increased', 'Decreased'],
    'Spotting': ['Light', 'Moderate'],
    'Pain': ['Mild', 'Moderate', 'Severe'],
    'Energy': ['High', 'Normal', 'Low'],
    'Feeding': ['Breastfeeding', 'Formula', 'Mixed'],
  };

  @override
  void initState() {
    super.initState();
    _log = widget.draft.copyWith();
    _notesController.text = _log.notes;
    _notesController.addListener(() {
      _log = _log.copyWith(notes: _notesController.text);
    });

    _flowExpanded = _log.bleedingFlowLevel != null;
    _dischargeExpanded = _log.dischargeAmount != null;
    for (final key in _log.symptoms.keys) {
      _symptomExpanded[key] = true;
    }

    // Pre-select the symptom tapped on the home quick-log chip.
    if (widget.preSelected != null) {
      final raw = widget.preSelected!;
      final key = SymptomsSubScreen.chipLabelToKey[raw] ?? raw;

      if (key == '_bleeding_flow') {
        _flowExpanded = true;
      } else if (_standardSymptoms.containsKey(key)) {
        _symptomExpanded[key] = true;
        if (!_log.symptoms.containsKey(key)) {
          final opts = _standardSymptoms[key]!;
          final newSymp = Map<String, String>.from(_log.symptoms)
            ..[key] = opts.first;
          _log = _log.copyWith(symptoms: newSymp);
        }
      }
    }
  }

  @override
  void dispose() {
    _notesController.dispose();
    _customSymptomController.dispose();
    super.dispose();
  }

  void _onBack() {
    Navigator.pop(context, _log);
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, result) {
        if (didPop) return;
        _onBack();
      },
      child: Scaffold(
        backgroundColor: CircaColors.bg,
        appBar: AppBar(
          backgroundColor: CircaColors.bg,
          elevation: 0,
          leading: IconButton(
            icon: const Icon(Icons.arrow_back, color: CircaColors.ink),
            onPressed: _onBack,
          ),
          centerTitle: true,
          title: const Text(
            "Symptoms",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: CircaColors.ink),
          ),
        ),
        body: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSymptomToggle(
                "Bleeding flow",
                _flowExpanded,
                (val) => setState(() {
                  _flowExpanded = val;
                  if (!val) _log = _log.copyWith(bleedingFlowLevel: null, bleedingFlowColour: null);
                }),
                _log.bleedingFlowLevel != null ? "${_log.bleedingFlowLevel}" : null,
                _buildFlowDetails(),
              ),
              
              _buildSymptomToggle(
                "Discharge",
                _dischargeExpanded,
                (val) => setState(() {
                  _dischargeExpanded = val;
                  if (!val) _log = _log.copyWith(dischargeAmount: null, dischargeColour: null);
                }),
                _log.dischargeAmount != null ? "${_log.dischargeAmount}" : null,
                _buildDischargeDetails(),
              ),

              ..._standardSymptoms.entries.map((e) {
                final name = e.key;
                final opts = e.value;
                final isExpanded = _symptomExpanded[name] ?? false;
                final val = _log.symptoms[name];
                
                return _buildSymptomToggle(
                  name,
                  isExpanded,
                  (v) => setState(() {
                    _symptomExpanded[name] = v;
                    if (!v) {
                      final newSymp = Map<String, String>.from(_log.symptoms)..remove(name);
                      _log = _log.copyWith(symptoms: newSymp);
                    }
                  }),
                  val,
                  _buildChipSelector(
                    opts,
                    val,
                    (selected) => setState(() {
                      final newSymp = Map<String, String>.from(_log.symptoms)..[name] = selected;
                      _log = _log.copyWith(symptoms: newSymp);
                    }),
                  ),
                );
              }),

              const SizedBox(height: 8),
              _buildCustomSymptomInput(),
              const SizedBox(height: 16),
              
              ..._log.customSymptoms.asMap().entries.map((entry) {
                final idx = entry.key;
                final cs = entry.value;
                final expandedKey = 'custom_${cs.name}';
                final isExpanded = _symptomExpanded[expandedKey] ?? true; 
                
                return _buildSymptomToggle(
                  cs.name,
                  isExpanded,
                  (v) => setState(() {
                    _symptomExpanded[expandedKey] = v;
                    if (!v) {
                      final newList = List<CustomSymptom>.from(_log.customSymptoms)..removeAt(idx);
                      _log = _log.copyWith(customSymptoms: newList);
                    }
                  }),
                  cs.detail.isNotEmpty ? cs.detail : null,
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text("Detail", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: CircaColors.muted)),
                      const SizedBox(height: 8),
                      TextField(
                        onChanged: (val) {
                          final newList = List<CustomSymptom>.from(_log.customSymptoms);
                          newList[idx] = CustomSymptom(name: cs.name, detail: val);
                          setState(() => _log = _log.copyWith(customSymptoms: newList));
                        },
                        controller: TextEditingController.fromValue(
                          TextEditingValue(
                            text: cs.detail,
                            selection: TextSelection.collapsed(offset: cs.detail.length),
                          ),
                        ),
                        style: const TextStyle(fontSize: 14),
                        decoration: InputDecoration(
                          hintText: "Add a detail...",
                          filled: true,
                          fillColor: CircaColors.bg,
                          isDense: true,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(color: CircaColors.line),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(20),
                            borderSide: const BorderSide(color: CircaColors.line),
                          ),
                        ),
                      ),
                    ],
                  ),
                );
              }),

              const SizedBox(height: 16),
              _buildNotesField(),
              const SizedBox(height: 48),
            ],
          ),
        ),
        floatingActionButton: Padding(
          padding: const EdgeInsets.only(bottom: 16),
          child: FloatingActionButton.extended(
            onPressed: () async {
              final nav = Navigator.of(context);
              final messenger = ScaffoldMessenger.of(context);
              
              // Idempotently commit the shared draft
              final toSave = _log.copyWith(loggedAt: AppClock.now());
              await storageService.saveLog(toSave);
              
              messenger.showSnackBar(
                const SnackBar(
                  content: Text("Saved ✓", style: TextStyle(fontWeight: FontWeight.w600)),
                  backgroundColor: CircaColors.ink,
                  duration: Duration(seconds: 2),
                  behavior: SnackBarBehavior.floating,
                ),
              );
              nav.pop(_log);
            },
            backgroundColor: CircaColors.accent,
            foregroundColor: CircaColors.accentDeep,
            elevation: 2,
            label: Text(
              _log.date.isAtSameMomentAs(DateTime(AppClock.now().year, AppClock.now().month, AppClock.now().day))
                  ? "Save today's log"
                  : "Save this day's log",
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            icon: const Icon(Icons.check, size: 20),
          ),
        ),
        floatingActionButtonLocation: FloatingActionButtonLocation.centerFloat,
      ),
    );
  }

  Widget _buildSymptomToggle(String title, bool isExpanded, ValueChanged<bool> onChanged, String? echoValue, Widget expandedContent) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: CircaColors.paper,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: CircaColors.line, width: 1.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          ListTile(
            title: Row(
              children: [
                Expanded(
                  child: Text(title, style: const TextStyle(fontWeight: FontWeight.w600, color: CircaColors.ink)),
                ),
                if (echoValue != null) ...[
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      echoValue,
                      style: CircaColors.helpText.copyWith(color: CircaColors.clay),
                      overflow: TextOverflow.ellipsis,
                      textAlign: TextAlign.right,
                    ),
                  ),
                ],
              ],
            ),
            trailing: Switch(
              value: isExpanded,
              onChanged: onChanged,
              activeThumbColor: CircaColors.clay,
              activeTrackColor: CircaColors.clay.withValues(alpha: 0.3),
            ),
          ),
          AnimatedCrossFade(
            firstChild: const SizedBox(height: 0, width: double.infinity),
            secondChild: Padding(
              padding: const EdgeInsets.only(left: 16, right: 16, bottom: 16),
              child: expandedContent,
            ),
            crossFadeState: isExpanded ? CrossFadeState.showSecond : CrossFadeState.showFirst,
            duration: const Duration(milliseconds: 250),
          ),
        ],
      ),
    );
  }

  Widget _buildFlowDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("How heavy?", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: CircaColors.muted)),
        const SizedBox(height: 8),
        _buildChipSelector(
          ['Spotting', 'Light', 'Medium', 'Heavy'],
          _log.bleedingFlowLevel,
          (val) => setState(() => _log = _log.copyWith(bleedingFlowLevel: val)),
        ),
        const SizedBox(height: 16),
        const Text("Colour", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: CircaColors.muted)),
        const SizedBox(height: 8),
        _buildColorChips([
          {'name': 'Bright red', 'hex': 0xFFC0392B},
          {'name': 'Dark red', 'hex': 0xFF7B241C},
          {'name': 'Brown', 'hex': 0xFF6E4B3A},
          {'name': 'Pink', 'hex': 0xFFCF7D92},
        ], _log.bleedingFlowColour, (val) => setState(() => _log = _log.copyWith(bleedingFlowColour: val))),
      ],
    );
  }

  Widget _buildDischargeDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("How much?", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: CircaColors.muted)),
        const SizedBox(height: 8),
        _buildChipSelector(
          ['A little', 'Noticeable'],
          _log.dischargeAmount,
          (val) => setState(() => _log = _log.copyWith(dischargeAmount: val)),
        ),
        const SizedBox(height: 16),
        const Text("Colour", style: TextStyle(fontWeight: FontWeight.w500, fontSize: 13, color: CircaColors.muted)),
        const SizedBox(height: 8),
        _buildColorChips([
          {'name': 'Clear', 'hex': 0xFFDFE6E6},
          {'name': 'White', 'hex': 0xFFF2EFE9},
          {'name': 'Creamy', 'hex': 0xFFE6D9B8},
          {'name': 'Yellow', 'hex': 0xFFD9C66A},
        ], _log.dischargeColour, (val) => setState(() => _log = _log.copyWith(dischargeColour: val))),
      ],
    );
  }

  Widget _buildChipSelector(List<String> options, String? selected, ValueChanged<String> onSelect) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: options.map((opt) {
        final isSelected = selected == opt;
        return GestureDetector(
          onTap: () => onSelect(opt),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: isSelected ? CircaColors.accentSoft : CircaColors.paper,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isSelected ? CircaColors.accent : CircaColors.line, width: 1.5),
            ),
            child: Text(
              opt,
              style: TextStyle(
                color: isSelected ? CircaColors.accentDeep : CircaColors.ink,
                fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildColorChips(List<Map<String, dynamic>> colors, String? selected, ValueChanged<String> onSelect) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: colors.map((c) {
        final name = c['name'] as String;
        final hex = c['hex'] as int;
        final isSelected = selected == name;
        
        return GestureDetector(
          onTap: () => onSelect(name),
          child: Container(
            padding: const EdgeInsets.only(left: 8, right: 16, top: 6, bottom: 6),
            decoration: BoxDecoration(
              color: isSelected ? CircaColors.accentSoft : CircaColors.paper,
              borderRadius: BorderRadius.circular(20),
              border: Border.all(color: isSelected ? CircaColors.accent : CircaColors.line, width: 1.5),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 16,
                  height: 16,
                  decoration: BoxDecoration(
                    color: Color(hex),
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.black12),
                  ),
                ),
                const SizedBox(width: 8),
                Text(
                  name,
                  style: TextStyle(
                    color: isSelected ? CircaColors.accentDeep : CircaColors.ink,
                    fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildNotesField() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("NOTES", style: CircaColors.eyebrow),
        const SizedBox(height: 8),
        TextField(
          controller: _notesController,
          maxLines: 4,
          style: const TextStyle(fontSize: 16, color: CircaColors.ink),
          decoration: InputDecoration(
            hintText: "Anything you'd like to remember about today...",
            hintStyle: const TextStyle(color: CircaColors.muted),
            filled: true,
            fillColor: CircaColors.paper,
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: CircaColors.line, width: 1.5),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(14),
              borderSide: const BorderSide(color: CircaColors.clay, width: 1.5),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildCustomSymptomInput() {
    return Row(
      children: [
        Expanded(
          child: TextField(
            controller: _customSymptomController,
            style: const TextStyle(fontSize: 15, color: CircaColors.ink),
            decoration: InputDecoration(
              hintText: "Create a custom symptom",
              hintStyle: const TextStyle(color: CircaColors.muted),
              filled: true,
              fillColor: CircaColors.paper,
              isDense: true,
              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: CircaColors.line, width: 1.5),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(20),
                borderSide: const BorderSide(color: CircaColors.clay, width: 1.5),
              ),
            ),
          ),
        ),
        const SizedBox(width: 12),
        ElevatedButton(
          onPressed: () {
            final text = _customSymptomController.text.trim();
            if (text.isNotEmpty) {
              setState(() {
                final newList = List<CustomSymptom>.from(_log.customSymptoms);
                newList.add(CustomSymptom(name: text, detail: ""));
                _log = _log.copyWith(customSymptoms: newList);
                _symptomExpanded['custom_$text'] = true; 
                _customSymptomController.clear();
              });
            }
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: CircaColors.accentSoft,
            foregroundColor: CircaColors.accentDeep,
            elevation: 0,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(20),
              side: const BorderSide(color: CircaColors.accent, width: 1.5),
            ),
            padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
          ),
          child: const Text("Add", style: TextStyle(fontWeight: FontWeight.w600)),
        ),
      ],
    );
  }
}
