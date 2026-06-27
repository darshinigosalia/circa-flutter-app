import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:circa_app/screens/onboarding/intro_screen.dart';

void main() {
  testWidgets('IntroScreen initial display and buttons test', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: IntroScreen(),
    ));

    // Verify initial text
    expect(find.text('Hi.'), findsOneWidget);
    expect(find.text("We're really glad you're here."), findsOneWidget);
    expect(find.text('Skip intro'), findsOneWidget);
    // "Let's begin" button is NOT visible initially
    expect(find.text("Let's begin"), findsNothing);

    // Advance through 4 page transitions (to page 4)
    for (int i = 0; i < 4; i++) {
      await tester.pumpAndSettle();
      await tester.pump(const Duration(milliseconds: 1000));
      await tester.pump();
    }

    // Advance from page 4 to page 5
    await tester.pumpAndSettle();
    await tester.pump(const Duration(milliseconds: 1000));
    await tester.pump(); // Draws page 5 initial frame

    // At the start of page 5, the button is in the tree but has opacity 0.0
    final initialOpacity = tester.widget<AnimatedOpacity>(
      find.descendant(
        of: find.byType(AnimatedSlide),
        matching: find.byType(AnimatedOpacity),
      ),
    );
    expect(initialOpacity.opacity, 0.0);

    // Let the animations and auto-advance timers complete.
    await tester.pumpAndSettle();

    // Now on last page, "Let's begin" button should be visible with opacity 1.0.
    final finalOpacity = tester.widget<AnimatedOpacity>(
      find.descendant(
        of: find.byType(AnimatedSlide),
        matching: find.byType(AnimatedOpacity),
      ),
    );
    expect(finalOpacity.opacity, 1.0);
    expect(find.text("Let's begin"), findsOneWidget);
  });

  testWidgets('IntroScreen tap left/right to navigate', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: IntroScreen(),
    ));

    // First page text
    expect(find.text('Hi.'), findsOneWidget);

    // Tap right side of the screen (default width 800, height 600)
    await tester.tapAt(const Offset(600, 300));
    await tester.pump(); // Start page transition

    // Now on second page
    expect(find.text('your hormones and your cycles'), findsOneWidget);

    // Tap left side of the screen
    await tester.tapAt(const Offset(200, 300));
    await tester.pump(); // Transition back

    // Back to first page
    expect(find.text('Hi.'), findsOneWidget);

    await tester.pumpAndSettle(const Duration(seconds: 15));
  });

  testWidgets('IntroScreen click pagination indicator to navigate', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: IntroScreen(),
    ));

    // Initially page 0
    expect(find.text('Hi.'), findsOneWidget);

    // Find the pagination indicators
    final rowFinder = find.descendant(
      of: find.byType(Column),
      matching: find.byType(Row),
    ).last; // The pagination row is the last Row in the Column.
    
    final childIndicators = find.descendant(
      of: rowFinder,
      matching: find.byType(GestureDetector),
    );

    // Tap the 3rd indicator (index 2)
    await tester.tap(childIndicators.at(2));
    await tester.pump();

    // Now on third page (page index 2)
    expect(find.text('When you notice how you feel,'), findsOneWidget);

    await tester.pumpAndSettle(const Duration(seconds: 15));
  });

  testWidgets('IntroScreen final page tap interactions', (WidgetTester tester) async {
    await tester.pumpWidget(const MaterialApp(
      home: IntroScreen(),
    ));

    // Navigate to final page immediately via indicator
    final rowFinder = find.descendant(
      of: find.byType(Column),
      matching: find.byType(Row),
    ).last;
    final childIndicators = find.descendant(
      of: rowFinder,
      matching: find.byType(GestureDetector),
    );
    await tester.tap(childIndicators.at(5));
    await tester.pump();

    // Verify button is in tree with opacity 0.0
    final opacityWidget1 = tester.widget<AnimatedOpacity>(
      find.descendant(
        of: find.byType(AnimatedSlide),
        matching: find.byType(AnimatedOpacity),
      ),
    );
    expect(opacityWidget1.opacity, 0.0);

    // Tap right side of the screen
    await tester.tapAt(const Offset(600, 300));
    await tester.pump(); // Complete page animations and start button animations
    await tester.pumpAndSettle(); // Let button animation finish

    // Verify button is now fully visible (opacity 1.0)
    final opacityWidget2 = tester.widget<AnimatedOpacity>(
      find.descendant(
        of: find.byType(AnimatedSlide),
        matching: find.byType(AnimatedOpacity),
      ),
    );
    expect(opacityWidget2.opacity, 1.0);

    // Tap left side of the screen
    await tester.tapAt(const Offset(200, 300));
    await tester.pump(); // Transition to page 4

    // Verify button is completely gone
    expect(find.text("Let's begin"), findsNothing);
  });
}
