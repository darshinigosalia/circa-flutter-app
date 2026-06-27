import 'dart:async';
import 'package:flutter/material.dart';
import '../theme/colors.dart';
import 'components.dart';
import 'track_fork_screen.dart';
import '../models/onboarding_data.dart';

class IntroSentence {
  final String sentence;
  final int gap; // milliseconds

  const IntroSentence({
    required this.sentence,
    required this.gap,
  });
}

class IntroPage {
  final List<IntroSentence> sentences;

  const IntroPage({
    required this.sentences,
  });
}

class IntroScreen extends StatefulWidget {
  const IntroScreen({super.key});

  @override
  State<IntroScreen> createState() => _IntroScreenState();
}

class _IntroScreenState extends State<IntroScreen> with TickerProviderStateMixin {
  int _currentPage = 0;
  bool _animationCompleted = false;
  Timer? _autoAdvanceTimer;

  static const int _pageDelayMs = 1000;
  static const int _sentenceAnimDurationMs = 600;

  static const List<IntroPage> _pages = [
    IntroPage(sentences: [
      IntroSentence(sentence: "Hi.", gap: 1000),
      IntroSentence(sentence: "We're really glad you're here.", gap: 0),
    ]),
    IntroPage(sentences: [
      IntroSentence(sentence: "your hormones and your cycles", gap: 1000),
      IntroSentence(sentence: "together tell one story", gap: 0),
    ]),
    IntroPage(sentences: [
      IntroSentence(sentence: "When you notice how you feel,", gap: 1000),
      IntroSentence(sentence: "you begin to understand your body's rhythm,", gap: 1000),
      IntroSentence(sentence: "whether you bleed, or not.", gap: 0),
    ]),
    IntroPage(sentences: [
      IntroSentence(sentence: "Circa is for anyone navigating periods, hormones, or cycles", gap: 1000),
      IntroSentence(sentence: "no matter how you identify.", gap: 0),
    ]),
    IntroPage(sentences: [
      IntroSentence(sentence: "Private. First, and always.", gap: 1000),
      IntroSentence(sentence: "Stored safely on your own device.", gap: 1000),
      IntroSentence(sentence: "No accounts, no ads, no data selling.", gap: 1000),
      IntroSentence(sentence: "And completely free.", gap: 0),
    ]),
    IntroPage(sentences: [
      IntroSentence(sentence: "However your body moves through time,", gap: 1000),
      IntroSentence(sentence: "we'll follow along", gap: 1000),
      IntroSentence(sentence: "gently, and", gap: 1000),
      IntroSentence(sentence: "always at your pace.", gap: 0),
    ]),
  ];

  AnimationController? _controller;
  final List<Animation<double>> _opacities = [];
  final List<Animation<Offset>> _slides = [];

  @override
  void initState() {
    super.initState();
    _setupAnimationsForPage();
  }

  void _setupAnimationsForPage() {
    _autoAdvanceTimer?.cancel();
    if (mounted) {
      _controller?.dispose();
    }

    final page = _pages[_currentPage];
    final sentences = page.sentences;
    final int numSentences = sentences.length;

    // Calculate start times for each sentence
    final List<int> startTimes = List.filled(numSentences, 0);
    for (int i = 1; i < numSentences; i++) {
      startTimes[i] = startTimes[i - 1] + _sentenceAnimDurationMs + sentences[i - 1].gap;
    }

    final int totalDurationMs = startTimes.last + _sentenceAnimDurationMs;

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: totalDurationMs),
    );

    _opacities.clear();
    _slides.clear();

    for (int i = 0; i < numSentences; i++) {
      final startMs = startTimes[i];
      final endMs = startMs + _sentenceAnimDurationMs;

      final startInterval = startMs / totalDurationMs;
      final endInterval = endMs / totalDurationMs;

      final curved = CurvedAnimation(
        parent: _controller!,
        curve: Interval(
          startInterval.clamp(0.0, 1.0),
          endInterval.clamp(0.0, 1.0),
          curve: Curves.easeOutCubic,
        ),
      );

      _opacities.add(Tween<double>(begin: 0.0, end: 1.0).animate(curved));
      _slides.add(Tween<Offset>(
        begin: const Offset(0, 24),
        end: Offset.zero,
      ).animate(curved));
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final disableAnimations = MediaQuery.of(context).disableAnimations;
      if (disableAnimations) {
        _controller!.value = 1.0;
        _onPageAnimationComplete();
      } else {
        _animationCompleted = false;
        final currentController = _controller!;
        currentController.forward().then((_) {
          if (mounted && _controller == currentController) {
            _onPageAnimationComplete();
          }
        });
      }
    });
  }

  void _onPageAnimationComplete() {
    setState(() {
      _animationCompleted = true;
    });

    if (_currentPage < _pages.length - 1) {
      _autoAdvanceTimer = Timer(const Duration(milliseconds: _pageDelayMs), () {
        if (mounted && _animationCompleted && _currentPage < _pages.length - 1) {
          _goToPage(_currentPage + 1);
        }
      });
    }
  }

  void _goToPage(int pageIndex) {
    if (pageIndex < 0 || pageIndex >= _pages.length) return;

    _autoAdvanceTimer?.cancel();

    setState(() {
      _currentPage = pageIndex;
      _animationCompleted = false;
    });

    _setupAnimationsForPage();
  }

  void _handleTapUp(TapUpDetails details) {
    final width = MediaQuery.of(context).size.width;
    final x = details.globalPosition.dx;
    if (x < width / 2) {
      // Left side tap -> Previous page
      if (_currentPage > 0) {
        _goToPage(_currentPage - 1);
      }
    } else {
      // Right side tap
      if (_currentPage < _pages.length - 1) {
        // Go to next page
        _goToPage(_currentPage + 1);
      } else if (_currentPage == _pages.length - 1 && !_animationCompleted) {
        // On final page and not yet completed -> immediately complete animations and show button
        _controller?.value = 1.0;
        _onPageAnimationComplete();
      }
    }
  }

  void _skipIntro() {
    _autoAdvanceTimer?.cancel();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(builder: (_) => const TrackForkScreen(data: OnboardingData())),
    );
  }

  @override
  void dispose() {
    _autoAdvanceTimer?.cancel();
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
                  onTapUp: _handleTapUp,
                  behavior: HitTestBehavior.opaque,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 26),
                      child: Align(
                        alignment: Alignment.centerLeft,
                        child: _buildPageContent(disableAnimations),
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
                    if (_currentPage == _pages.length - 1) ...[
                      AnimatedSlide(
                        offset: _animationCompleted ? Offset.zero : const Offset(0.0, 0.25),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutCubic,
                        child: AnimatedOpacity(
                          opacity: _animationCompleted ? 1.0 : 0.0,
                          duration: const Duration(milliseconds: 600),
                          curve: Curves.easeOutCubic,
                          child: CircaButton(
                            label: "Let's begin",
                            onPressed: _skipIntro,
                          ),
                        ),
                      ),
                      const SizedBox(height: 24),
                    ],
                    // Progress ticks
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: List.generate(_pages.length, (index) {
                        final isFilled = index <= _currentPage;
                        return GestureDetector(
                          onTap: () => _goToPage(index),
                          behavior: HitTestBehavior.opaque,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 12),
                            child: Container(
                              width: 24,
                              height: 4,
                              decoration: BoxDecoration(
                                color: isFilled ? CircaColors.accent : CircaColors.line,
                                borderRadius: BorderRadius.circular(2),
                              ),
                            ),
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

  Widget _buildPageContent(bool disableAnimations) {
    final page = _pages[_currentPage];
    if (_controller == null || _opacities.length < page.sentences.length || _slides.length < page.sentences.length) {
      return const SizedBox.shrink();
    }

    final List<Widget> widgets = [];

    for (int i = 0; i < page.sentences.length; i++) {
      if (i > 0) {
        widgets.add(const SizedBox(height: 16));
      }

      final sentence = page.sentences[i].sentence;
      final opacity = _opacities[i];
      final slide = _slides[i];

      widgets.add(
        AnimatedBuilder(
          animation: _controller!,
          builder: (context, child) {
            final valOpacity = disableAnimations ? 1.0 : opacity.value;
            final valOffset = disableAnimations ? Offset.zero : slide.value;
            return Opacity(
              opacity: valOpacity,
              child: Transform.translate(
                offset: valOffset,
                child: child,
              ),
            );
          },
          child: Text(
            sentence,
            textAlign: TextAlign.left,
            style: CircaColors.title.copyWith(
              fontWeight: FontWeight.w500,
              height: 1.5, // Increased line spacing
            ),
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      crossAxisAlignment: CrossAxisAlignment.start,
      children: widgets,
    );
  }
}
