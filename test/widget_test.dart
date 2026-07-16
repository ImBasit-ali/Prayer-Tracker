// Basic widget test for Muslim Prayer Tracker app
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter/widgets.dart';
import 'package:muslim_prayer_tracker/main.dart';
import 'package:visibility_detector/visibility_detector.dart';

void main() {
  testWidgets('App launches successfully', (WidgetTester tester) async {
    final originalBuilder = ErrorWidget.builder;
    VisibilityDetectorController.instance.updateInterval = Duration.zero;

    // Build our app and trigger a frame.
    await tester.pumpWidget(const MyApp());

    // Verify that splash screen appears
    expect(find.text('Muslim Prayer Tracker'), findsOneWidget);

    // Let the splash screen timer run and transition to home screen
    await tester.pump(const Duration(milliseconds: 2500));
    // Pump a few frames to let the page transition animation complete
    for (int i = 0; i < 10; i++) {
      await tester.pump(const Duration(milliseconds: 100));
    }

    // Restore ErrorWidget.builder to avoid test framework assertion failure
    ErrorWidget.builder = originalBuilder;
  });
}
