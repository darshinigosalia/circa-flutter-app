import 'package:flutter/material.dart';
import '../../theme/colors.dart';
import '../../services/storage_service.dart';
import '../../utils/route_resolver.dart';
import 'components.dart';
import '../charts/charts_screen.dart';
import '../track/med_track_screen.dart';
import '../track/track_hub_screen.dart';
import '../settings/settings_screen.dart';
import '../onboarding/intro_screen.dart';
import '../../models/onboarding_data.dart';
import '../../models/cycle_type.dart';
import 'package:circa_app/utils/app_clock.dart';

class CircaDrawer extends StatelessWidget {
  final StorageService storage;
  final String activeRoute;

  const CircaDrawer({super.key, required this.storage, this.activeRoute = ''});

  @override
  Widget build(BuildContext context) {
    return Drawer(
      backgroundColor: CircaColors.bg,
      child: SafeArea(
        child: Column(
          children: [
            // Header
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 32),
              child: Row(
                children: [
                  const CircaLogo(size: 32),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text("circa", style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700, color: CircaColors.ink)),
                        Text("your cycle, gently followed", style: CircaColors.helpText.copyWith(fontSize: 14)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const Divider(color: CircaColors.line, height: 1),
            const SizedBox(height: 16),
            
            // Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                children: [
                  _buildItem(
                    context, 
                    icon: Icons.home_outlined, 
                    label: "Home", 
                    isActive: activeRoute == 'Home',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(builder: (_) => resolveHome(storage.profile)),
                        (route) => false,
                      );
                    },
                  ),
                  _buildItem(
                    context, 
                    icon: Icons.add_circle_outline, 
                    label: "Track", 
                    isActive: activeRoute == 'Track',
                    onTap: () {
                      Navigator.pop(context);
                      final profile = storage.profile;
                      if (profile != null) {
                        Navigator.of(context).push(
                          MaterialPageRoute(
                            builder: (_) => TrackHubScreen(
                              date: AppClock.now(),
                              storage: storage,
                              data: OnboardingData(
                                cycleType: profile.cycleType,
                                isPregnant: profile.isPregnant,
                                lastPeriod: profile.lastPeriod,
                                showFertility: profile.showFertility,
                              ),
                            ),
                          ),
                        );
                      }
                    },
                  ),
                  _buildItem(
                    context, 
                    icon: Icons.bar_chart_outlined, 
                    label: "Charts", 
                    isActive: activeRoute == 'Charts',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => ChartsScreen(storage: storage)),
                      );
                    },
                  ),
                  _buildItem(
                    context, 
                    icon: Icons.medical_services_outlined, 
                    label: "Medications & appointments", 
                    isActive: activeRoute == 'Meds',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => MedTrackScreen(storage: storage)),
                      );
                    },
                  ),
                  _buildItem(
                    context, 
                    icon: Icons.settings_outlined, 
                    label: "Settings", 
                    isActive: activeRoute == 'Settings',
                    onTap: () {
                      Navigator.pop(context);
                      Navigator.of(context).push(
                        MaterialPageRoute(builder: (_) => SettingsScreen(storage: storage)),
                      );
                    },
                  ),
                ],
              ),
            ),
            
            // Footer
            const Divider(color: CircaColors.line, height: 1),
          ],
        ),
      ),
    );
  }

  Widget _buildItem(BuildContext context, {required IconData icon, required String label, required bool isActive, required VoidCallback onTap}) {
    return ListTile(
      leading: Icon(icon, color: isActive ? CircaColors.accentDeep : CircaColors.ink),
      title: Text(
        label,
        style: TextStyle(
          fontSize: 16,
          fontWeight: isActive ? FontWeight.w600 : FontWeight.w500,
          color: isActive ? CircaColors.accentDeep : CircaColors.ink,
        ),
      ),
      selected: isActive,
      selectedTileColor: CircaColors.accentSoft,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      onTap: onTap,
    );
  }
}
