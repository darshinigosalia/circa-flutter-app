import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_gallery_saver/image_gallery_saver.dart';
import 'package:flutter_dynamic_icon/flutter_dynamic_icon.dart';
import '../../theme/colors.dart';
import '../../services/storage_service.dart';
import '../common/components.dart';

class StealthModeScreen extends StatefulWidget {
  final StorageService storage;

  const StealthModeScreen({super.key, required this.storage});

  @override
  State<StealthModeScreen> createState() => _StealthModeScreenState();
}

class _StealthModeScreenState extends State<StealthModeScreen> {
  late bool _isDiscreet;
  String? _currentIcon;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    _isDiscreet = widget.storage.getSetting('isDiscreetModeEnabled', defaultValue: false);
    _currentIcon = widget.storage.discreetIconName;
  }

  Future<void> _toggleDiscreetMode(bool val) async {
    setState(() => _isDiscreet = val);
    widget.storage.saveSetting('isDiscreetModeEnabled', val);

    try {
      if (await FlutterDynamicIcon.supportsAlternateIcons) {
        if (val) {
          // If turning on, set to calculator by default if none selected
          final targetIcon = _currentIcon ?? 'calculator';
          await FlutterDynamicIcon.setAlternateIconName(targetIcon);
          widget.storage.setDiscreetIconName(targetIcon);
          setState(() => _currentIcon = targetIcon);
        } else {
          // If turning off, revert to default
          await FlutterDynamicIcon.setAlternateIconName(null);
          // Keep the preference of which icon they had, but disable the mode
        }
      }
    } catch (e) {
      debugPrint("Failed to change icon: $e");
    }
  }

  Future<void> _setSpecificIcon(String? name) async {
    try {
      if (await FlutterDynamicIcon.supportsAlternateIcons) {
        await FlutterDynamicIcon.setAlternateIconName(name);
        widget.storage.setDiscreetIconName(name);
        setState(() => _currentIcon = name);
      }
    } catch (e) {
      debugPrint("Failed to change icon: $e");
    }
  }

  Future<void> _saveAssetsToGallery() async {
    setState(() => _isSaving = true);
    try {
      final assets = [
        'assets/stealth/calculatorIcon.png',
        'assets/stealth/notesIcon.png',
        'assets/stealth/weatherIcon.png',
        'assets/stealth/clockIcon.png',
      ];

      for (var asset in assets) {
        final byteData = await rootBundle.load(asset);
        final bytes = byteData.buffer.asUint8List();
        await ImageGallerySaver.saveImage(bytes, name: asset.split('/').last.split('.').first);
      }

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Decoy icons saved to Camera Roll.")),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Failed to save icons.")),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
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
        title: const Text(
          "Stealth Mode",
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: CircaColors.ink),
        ),
      ),
      body: ListView(
        padding: const EdgeInsets.all(26),
        children: [
          const Text(
            "Privacy & Discretion",
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.w600, color: CircaColors.ink),
          ),
          const SizedBox(height: 12),
          const Text(
            "Your safety and privacy are paramount. Stealth mode allows you to disguise the app's icon on your device.",
            style: TextStyle(fontSize: 16, color: CircaColors.ink, height: 1.5),
          ),
          const SizedBox(height: 32),
          
          // Toggle Container
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            decoration: BoxDecoration(
              color: CircaColors.paper,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: CircaColors.line),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  "Enable Discreet Mode",
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500, color: CircaColors.ink),
                ),
                Switch.adaptive(
                  value: _isDiscreet,
                  onChanged: _toggleDiscreetMode,
                  activeColor: CircaColors.accent,
                ),
              ],
            ),
          ),

          if (_isDiscreet) ...[
            const SizedBox(height: 24),
            Text("Choose your decoy icon:", style: CircaColors.eyebrow),
            const SizedBox(height: 12),
            Container(
              decoration: BoxDecoration(
                color: CircaColors.paper,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: CircaColors.line),
              ),
              child: Column(
                children: [
                  _buildIconOption('calculator', 'Calculator', Icons.calculate),
                  const Divider(height: 1, color: CircaColors.line),
                  _buildIconOption('notes', 'Notes', Icons.notes),
                  const Divider(height: 1, color: CircaColors.line),
                  _buildIconOption('weather', 'Weather', Icons.cloud),
                  const Divider(height: 1, color: CircaColors.line),
                  _buildIconOption('clock', 'Clock', Icons.access_time),
                ],
              ),
            ),
          ],

          if (Platform.isIOS) ...[
            const SizedBox(height: 48),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: CircaColors.paper,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: CircaColors.accentSoft, width: 2),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.shield_outlined, color: CircaColors.accent),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "Want absolute stealth?",
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.w600, color: CircaColors.accent),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Due to Apple's constraints, the app name under the icon will still say 'Circa'. To safely disguise both the icon AND the name on iOS:",
                    style: TextStyle(fontSize: 15, color: CircaColors.ink, height: 1.5),
                  ),
                  const SizedBox(height: 20),
                  _buildStep("1", "Tap the button below to save our decoy icons to your Camera Roll."),
                  _buildStep("2", "Open Apple's native 'Shortcuts' app."),
                  _buildStep("3", "Create a new shortcut, add the 'Open App' action, and select Circa."),
                  _buildStep("4", "Tap the arrow at the top, select 'Add to Home Screen'."),
                  _buildStep("5", "Rename it (e.g., 'Calculator' or 'Math Game') and tap the icon next to it to upload the decoy image you saved."),
                  _buildStep("6", "Remove the original Circa app from your Home Screen (move it to the App Library)."),
                  
                  const SizedBox(height: 24),
                  SizedBox(
                    width: double.infinity,
                    child: CircaButton(
                      label: _isSaving ? "Saving..." : "Save Decoy Icons to Camera Roll",
                      onPressed: _isSaving ? () {} : _saveAssetsToGallery,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 40),
        ],
      ),
    );
  }

  Widget _buildIconOption(String name, String label, IconData icon) {
    final isSelected = _currentIcon == name;
    return ListTile(
      leading: Icon(icon, color: isSelected ? CircaColors.accent : CircaColors.muted),
      title: Text(label, style: const TextStyle(fontWeight: FontWeight.w500)),
      trailing: isSelected ? const Icon(Icons.check, color: CircaColors.accent) : null,
      onTap: () => _setSpecificIcon(name),
    );
  }

  Widget _buildStep(String number, String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 24,
            height: 24,
            decoration: const BoxDecoration(
              color: CircaColors.accent,
              shape: BoxShape.circle,
            ),
            alignment: Alignment.center,
            child: Text(
              number,
              style: const TextStyle(color: Colors.white, fontSize: 12, fontWeight: FontWeight.bold),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Text(text, style: const TextStyle(fontSize: 15, color: CircaColors.ink, height: 1.4)),
          ),
        ],
      ),
    );
  }
}
