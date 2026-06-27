import 'package:flutter/material.dart';
import '../theme/colors.dart';
import 'components.dart';
import 'track_fork_screen.dart';
import '../models/onboarding_data.dart';

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> with TickerProviderStateMixin {
  int _currentBeat = 0;
  bool _animationCompleted = false;

  final List<List<String>> _beats = [
    [
      "Hi.",
      "[gap]",
      "We're really glad you're here.",
    ],
    [
      "your hormones and your cycles",
      "together tell one story",
    ],
    [
      "When you notice how you feel,",
      "you begin to understand your body's rhythm,",
      "whether you bleed, or not.",
    ],
    [
      "Circa is for anyone navigating periods, hormones, or cycles",
      "[gap]",
      "no matter how you identify.",
    ],
    [
      "Private. First, and always.",
      "[gap]",
      "Stored safely on your own device.",
      "No accounts, no ads, no data selling.",
      "[gap]",
      "And completely free.",
    ],
    [
      "However your body moves through time,",
      "[gap]",
      "we'll follow along",
      "[gap]",
      "gently, and",
      "always at your pace.",
    ],
  ];

  AnimationController? _controller;
  final List<Animation<double>> _opacities = [];

  @override
  void initState() {
    super.initState();
    _setupAnimationsForBeat();
  }

  void _setupAnimationsForBeat() {
    if (mounted) {
      // Clear previous animations
      _controller?.dispose();
    }
    
    final lines = _beats[_currentBeat];
    
    int totalMsForBeat = 0;
    for (int i = 0; i < lines.length; i++) {
      if (lines[i] == "[gap]") {
        totalMsForBeat += 2500;
      } else {
        totalMsForBeat += 3500;
      }
    }
    
    final exactDurationMs = totalMsForBeat + 100; // a little padding
    
    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: exactDurationMs),
    );

    _opacities.clear();

    int currentStartMs = 0;
    
    for (int i = 0; i < lines.length; i++) {
      if (lines[i] == "[gap]") {
        currentStartMs += 2500;
      } else {
        final startMs = currentStartMs;
        final endMs = startMs + 650; // 650ms duration
        
        final curved = CurvedAnimation(
          parent: _controller!,
          curve: Interval(
            startMs / exactDurationMs,
            endMs / exactDurationMs,
            curve: Curves.easeOutCubic,
          ),
        );
        
        _opacities.add(Tween<double>(begin: 0.0, end: 1.0).animate(curved));
        
        currentStartMs += 3500; // Slower stagger for next real line
      }
    }

    // Wait until build is complete so we can check MediaQuery for reduced motion
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final disableAnimations = MediaQuery.of(context).disableAnimations;
      if (disableAnimations) {
        _controller!.value = 1.0; // Instantly complete
        _onBeatAnimationComplete();
      } else {
        _animationCompleted = false;
        _controller!.forward().then((_) {
          if (mounted) _onBeatAnimationComplete();
        });
      }
    });
  }

  void _onBeatAnimationComplete() {
    setState(() {
      _animationCompleted = true;
    });
    
    if (_currentBeat < _beats.length - 1) {
      // Read pause then auto-advance
      Future.delayed(const Duration(seconds: 3)).then((_) {
        if (mounted && _animationCompleted && _currentBeat < _beats.length - 1) {
          _advanceBeat();
        }
      });
    }
  }

  void _advanceBeat() {
    if (_currentBeat < _beats.length - 1) {
      setState(() {
        _currentBeat++;
        _animationCompleted = false;
      });
      _setupAnimationsForBeat();
    }
  }

  void _handleTap() {
    if (_currentBeat < _beats.length - 1) {
      if (!_animationCompleted) {
        // If still animating, jump to end of beat
        _controller!.value = 1.0;
        _onBeatAnimationComplete();
      } else {
        _advanceBeat();
      }
    }
  }

  void _skipIntro() {
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const TrackForkScreen(data: OnboardingData())),
    );
  }

  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final disableAnimations = MediaQuery.of(context).disableAnimations;

    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            stops: [0.0, 0.7],
            colors: [CircaColors.accentSoft, CircaColors.paper],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              // Top Bar
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 16),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    TextButton(
                      onPressed: _skipIntro,
                      child: Text(
                        "Skip intro",
                        style: CircaColors.helpText.copyWith(
                          color: CircaColors.muted,
                          decoration: TextDecoration.underline,
                          decorationColor: CircaColors.muted,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              
              // Body
              Expanded(
                child: GestureDetector(
                  onTap: _handleTap,
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 26),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _buildBeatContent(disableAnimations),
                      ),
                    ),
                  ),
                ),
              ),

              // Bottom Area
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 26, vertical: 32),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    if (_currentBeat == _beats.length - 1)
                      AnimatedOpacity(
                        key: const ValueKey('lets_begin_btn'),
                        duration: const Duration(milliseconds: 400),
                        opacity: disableAnimations || _animationCompleted ? 1.0 : 0.0,
                        child: CircaButton(
                          label: "Let's begin",
                          onPressed: () {
                            _skipIntro();
                          },
                        ),
                      )
                    else
                      AnimatedOpacity(
                        key: ValueKey('tap_to_continue_$_currentBeat'),
                        duration: const Duration(milliseconds: 400),
                        opacity: disableAnimations || _animationCompleted ? 1.0 : 0.0,
                        child: Text(
                          "tap to continue",
                          style: CircaColors.helpText.copyWith(fontSize: 14),
                        ),
                      ),
                    const SizedBox(height: 24),
                    // Progress ticks
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(6, (index) {
                        final isFilled = index <= _currentBeat;
                        return Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          width: 24,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isFilled ? CircaColors.accent : CircaColors.line,
                            borderRadius: BorderRadius.circular(2),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBeatContent(bool disableAnimations) {
    final lines = _beats[_currentBeat];
    List<Widget> widgets = [];
    int realLineIndex = 0;

    for (int i = 0; i < lines.length; i++) {
      if (lines[i] == "[gap]") {
        widgets.add(const SizedBox(height: 16));
      } else {
        final animIndex = realLineIndex;
        final opacity = _opacities[animIndex];
        
        widgets.add(
          AnimatedBuilder(
            animation: _controller!,
            builder: (context, child) {
              final valOpacity = disableAnimations ? 1.0 : opacity.value;
              return Opacity(
                opacity: valOpacity,
                child: child,
              );
            },
            child: Text(
              lines[i],
              textAlign: TextAlign.left,
              style: CircaColors.title.copyWith(
                fontWeight: FontWeight.w500,
                height: 1.5, // Increased line spacing
              ),
            ),
          ),
        );
        realLineIndex++;
      }
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}
