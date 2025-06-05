import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subtrackr/presentation/widgets/home/summary_card.dart';

void main() {
  group('SummaryCard Widget Tests', () {
    testWidgets('should display all required elements', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SummaryCard(
              title: 'Active Subscriptions',
              value: '10',
              icon: Icons.check_circle_rounded,
              color: Colors.blue,
            ),
          ),
        ),
      );

      // Verify all elements are displayed
      expect(find.text('Active Subscriptions'), findsOneWidget);
      expect(find.text('10'), findsOneWidget);
      expect(find.byIcon(Icons.check_circle_rounded), findsOneWidget);
    });

    testWidgets('should display optional subtitle', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SummaryCard(
              title: 'Local Subscriptions',
              value: '5',
              icon: Icons.home_rounded,
              color: Colors.green,
              subtitle: 'USD',
            ),
          ),
        ),
      );

      // Verify subtitle is displayed
      expect(find.text('USD'), findsOneWidget);
    });

    testWidgets('should display optional flag', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SummaryCard(
              title: 'Local Subscriptions',
              value: '5',
              icon: Icons.home_rounded,
              color: Colors.green,
              flag: '🇺🇸',
            ),
          ),
        ),
      );

      // Verify flag is displayed
      expect(find.text('🇺🇸'), findsOneWidget);
    });

    testWidgets('should apply correct styling', (WidgetTester tester) async {
      const testColor = Colors.blue;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SummaryCard(
              title: 'Test Card',
              value: '42',
              icon: Icons.star,
              color: testColor,
            ),
          ),
        ),
      );

      // Find the icon container
      final iconContainerFinder = find.descendant(
        of: find.byType(Container),
        matching: find.byIcon(Icons.star),
      ).first;
      
      final iconWidget = tester.widget<Icon>(find.byIcon(Icons.star));
      
      // Verify icon color
      expect(iconWidget.color, testColor);
      expect(iconWidget.size, 22);
    });

    testWidgets('should have correct card dimensions', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: Row(
              children: [
                SummaryCard(
                  title: 'Test Card',
                  value: '10',
                  icon: Icons.star,
                  color: Colors.blue,
                ),
              ],
            ),
          ),
        ),
      );

      // Find the card container
      final containerFinder = find.descendant(
        of: find.byType(Card),
        matching: find.byType(Container),
      ).first;
      
      final container = tester.widget<Container>(containerFinder);
      
      // Verify width
      expect(container.constraints?.maxWidth ?? 0, 180);
      
      // Verify padding
      expect(container.padding, const EdgeInsets.all(16));
    });

    testWidgets('should handle long text with ellipsis', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: SizedBox(
              width: 200,
              child: SummaryCard(
                title: 'This is a very long title that should be truncated',
                value: '999999999',
                icon: Icons.star,
                color: Colors.blue,
                subtitle: 'This is also a very long subtitle',
              ),
            ),
          ),
        ),
      );

      // Find text widgets
      final titleFinder = find.text('This is a very long title that should be truncated');
      final valueFinder = find.text('999999999');
      final subtitleFinder = find.text('This is also a very long subtitle');
      
      // Get text widgets
      final titleText = tester.widget<Text>(titleFinder);
      final valueText = tester.widget<Text>(valueFinder);
      final subtitleText = tester.widget<Text>(subtitleFinder);
      
      // Verify overflow handling
      expect(titleText.overflow, TextOverflow.ellipsis);
      expect(valueText.overflow, TextOverflow.ellipsis);
      expect(subtitleText.overflow, TextOverflow.ellipsis);
    });
  });
} 