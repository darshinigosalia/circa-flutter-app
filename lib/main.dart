import 'package:flutter/material.dart';
import 'theme/colors.dart';
import 'screens/onboarding/intro_screen.dart';
import 'services/storage_service.dart';
import 'utils/route_resolver.dart';

import 'package:hive_flutter/hive_flutter.dart';
import 'package:local_auth/local_auth.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Hive.initFlutter();
  await Hive.openBox<String>('logs');
  await Hive.openBox<String>('profile');
  await Hive.openBox<String>('medications');
  await Hive.openBox<String>('appointments');
  await Hive.openBox<dynamic>('settings');
  await storageService.init();
  runApp(const CircaApp());
}

class CircaApp extends StatefulWidget {
  const CircaApp({super.key});

  @override
  State<CircaApp> createState() => _CircaAppState();
}

class _CircaAppState extends State<CircaApp> with WidgetsBindingObserver {
  bool _isLocked = false;
  final LocalAuthentication _localAuth = LocalAuthentication();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    if (storageService.appLockEnabled) {
      _isLocked = true;
      _authenticate();
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (!storageService.appLockEnabled) return;
    
    if (state == AppLifecycleState.paused || state == AppLifecycleState.inactive) {
      setState(() {
        _isLocked = true;
      });
    } else if (state == AppLifecycleState.resumed) {
      if (_isLocked) {
        _authenticate();
      }
    }
  }

  Future<void> _authenticate() async {
    try {
      final authenticated = await _localAuth.authenticate(
        localizedReason: 'Please authenticate to access Circa',
        biometricOnly: false,
        persistAcrossBackgrounding: true,
      );
      if (authenticated) {
        setState(() {
          _isLocked = false;
        });
      }
    } catch (e) {
      // Allow retry via button
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: storageService,
      builder: (context, _) {
        return MaterialApp(
          title: 'Circa',
          theme: CircaColors.theme,
          debugShowCheckedModeBanner: false,
          home: resolveHome(storageService.profile),
          builder: (context, child) {
            return Stack(
              children: [
                if (child != null) child,
                if (_isLocked)
                  Positioned.fill(
                    child: Directionality(
                      textDirection: TextDirection.ltr,
                      child: Material(
                        color: CircaColors.bg,
                        child: Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Icon(Icons.lock_outline, size: 64, color: CircaColors.muted),
                              const SizedBox(height: 24),
                              ElevatedButton(
                                onPressed: _authenticate,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: CircaColors.accentSoft,
                                  foregroundColor: CircaColors.ink,
                                  elevation: 0,
                                ),
                                child: const Text("Unlock"),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        );
      }
    );
  }
}
