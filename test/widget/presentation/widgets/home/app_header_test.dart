import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subtrackr/core/constants/app_constants.dart';
import 'package:subtrackr/presentation/widgets/home/app_header.dart';

void main() {
  group('AppHeader Widget Tests', () {
    testWidgets('should display app name correctly', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppHeader(),
          ),
        ),
      );

      // Verify app name is displayed
      expect(find.text(AppConstants.APP_NAME), findsOneWidget);
      
      // Verify tagline is displayed
      expect(find.text('Track your subscriptions'), findsOneWidget);
    });

    testWidgets('should apply correct styling in light theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.light(),
          home: const Scaffold(
            body: AppHeader(),
          ),
        ),
      );

      // Find the app name text widget
      final appNameFinder = find.text(AppConstants.APP_NAME);
      final Text appNameWidget = tester.widget(appNameFinder);
      
      // Verify the text style
      expect(appNameWidget.style?.fontSize, 32);
      expect(appNameWidget.style?.fontWeight, FontWeight.bold);
      expect(appNameWidget.style?.color, Colors.black);
    });

    testWidgets('should apply correct styling in dark theme', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          theme: ThemeData.dark(),
          home: const Scaffold(
            body: AppHeader(),
          ),
        ),
      );

      // Find the app name text widget
      final appNameFinder = find.text(AppConstants.APP_NAME);
      final Text appNameWidget = tester.widget(appNameFinder);
      
      // Verify the text style
      expect(appNameWidget.style?.fontSize, 32);
      expect(appNameWidget.style?.fontWeight, FontWeight.bold);
      expect(appNameWidget.style?.color, Colors.white);
    });

    testWidgets('should have correct padding', (WidgetTester tester) async {
      await tester.pumpWidget(
        const MaterialApp(
          home: Scaffold(
            body: AppHeader(),
          ),
        ),
      );

      // Find the Container with padding
      final containerFinder = find.byType(Container).first;
      final Container container = tester.widget(containerFinder);
      
      // Verify padding
      expect(container.padding, const EdgeInsets.fromLTRB(20, 20, 20, 10));
    });
  });
} 