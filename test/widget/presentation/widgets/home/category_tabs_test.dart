import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:subtrackr/presentation/widgets/home/category_tabs.dart';

void main() {
  group('CategoryTabs Widget Tests', () {
    final testCategories = ['All', 'Active', 'Due Soon', 'Paused', 'Cancelled'];
    
    testWidgets('should display all categories', (WidgetTester tester) async {
      int selectedIndex = 0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryTabs(
              selectedIndex: selectedIndex,
              categories: testCategories,
              onCategorySelected: (_) {},
            ),
          ),
        ),
      );

      // Verify all categories are displayed
      for (final category in testCategories) {
        expect(find.text(category), findsOneWidget);
      }
    });

    testWidgets('should highlight selected category', (WidgetTester tester) async {
      int selectedIndex = 1; // Active
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryTabs(
              selectedIndex: selectedIndex,
              categories: testCategories,
              onCategorySelected: (_) {},
            ),
          ),
        ),
      );

      // Find the selected category text
      final activeTextFinder = find.text('Active');
      final Text activeText = tester.widget(activeTextFinder);
      
      // Verify selected styling
      expect(activeText.style?.fontWeight, FontWeight.w600);
    });

    testWidgets('should call onCategorySelected when tapped', (WidgetTester tester) async {
      int selectedIndex = 0;
      int? tappedIndex;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryTabs(
              selectedIndex: selectedIndex,
              categories: testCategories,
              onCategorySelected: (index) {
                tappedIndex = index;
              },
            ),
          ),
        ),
      );

      // Tap on "Due Soon" category (index 2)
      await tester.tap(find.text('Due Soon'));
      await tester.pumpAndSettle();
      
      // Verify callback was called with correct index
      expect(tappedIndex, 2);
    });

    testWidgets('should animate tab changes', (WidgetTester tester) async {
      int selectedIndex = 0;
      
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: StatefulBuilder(
              builder: (context, setState) {
                return CategoryTabs(
                  selectedIndex: selectedIndex,
                  categories: testCategories,
                  onCategorySelected: (index) {
                    setState(() {
                      selectedIndex = index;
                    });
                  },
                );
              },
            ),
          ),
        ),
      );

      // Initially, "All" should be selected
      expect(selectedIndex, 0);
      
      // Tap on "Active"
      await tester.tap(find.text('Active'));
      await tester.pumpAndSettle();
      
      // Find AnimatedContainer widgets
      final animatedContainers = find.byType(AnimatedContainer);
      expect(animatedContainers, findsNWidgets(testCategories.length));
    });

    testWidgets('should have correct dimensions', (WidgetTester tester) async {
      await tester.pumpWidget(
        MaterialApp(
          home: Scaffold(
            body: CategoryTabs(
              selectedIndex: 0,
              categories: testCategories,
              onCategorySelected: (_) {},
            ),
          ),
        ),
      );

      // Find the main container
      final containerFinder = find.byType(Container).first;
      final container = tester.widget<Container>(containerFinder);
      
      // Verify height
      expect(container.constraints?.maxHeight ?? 0, 50);
      
      // Verify margin
      expect(container.margin, const EdgeInsets.fromLTRB(20, 8, 20, 16));
    });
  });
} 