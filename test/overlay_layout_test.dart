import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:sunnah_steps/widgets/today_checklist_overlay.dart';
import 'package:sunnah_steps/widgets/checklist_item_card.dart';
import 'package:sunnah_steps/models/checklist_item.dart';

void main() {
  testWidgets(
      'Overlay shows 3 items and ≥ 40 px gap between card border and header',
      (tester) async {
    // Create test data
    final testItems = [
      ChecklistItem(
        id: 'test1',
        title: 'Test Sunnah 1',
        benefits: 'Test benefits 1',
        hadithEnglish: 'Test hadith 1',
        hadithArabic: 'Test hadith arabic 1',
        tags: ['test'],
        category: 'test',
        priority: 8,
        dateAssigned: DateTime.now(),
      ),
      ChecklistItem(
        id: 'test2',
        title: 'Test Sunnah 2',
        benefits: 'Test benefits 2',
        hadithEnglish: 'Test hadith 2',
        hadithArabic: 'Test hadith arabic 2',
        tags: ['test'],
        category: 'test',
        priority: 6,
        dateAssigned: DateTime.now(),
      ),
      ChecklistItem(
        id: 'test3',
        title: 'Test Sunnah 3',
        benefits: 'Test benefits 3',
        hadithEnglish: 'Test hadith 3',
        hadithArabic: 'Test hadith arabic 3',
        tags: ['test'],
        category: 'test',
        priority: 4,
        dateAssigned: DateTime.now(),
      ),
    ];

    // Pump the overlay in isolation
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: TodayChecklistOverlay(
            onComplete: () {},
            onSkip: () {},
            testItems: testItems,
          ),
        ),
      ),
    );

    // Wait for initial load and animations with timeout
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 100));
    await tester.pump(const Duration(milliseconds: 500));
    await tester.pump(const Duration(milliseconds: 1000));

    // 1️⃣  Exactly three checklist items
    expect(find.byType(ChecklistItemCard), findsNWidgets(3));

    // 2️⃣  Measure vertical gap
    // -─ locate widgets
    final headerFinder = find.text("Today's Sunnah Checklist");
    final cardFinder   = find.byKey(const ValueKey('ChecklistCard'));

    // sanity checks
    expect(headerFinder, findsOneWidget);
    expect(cardFinder,   findsOneWidget);

    // get global y-positions
    final headerBox = tester.renderObject<RenderBox>(headerFinder);
    final cardBox   = tester.renderObject<RenderBox>(cardFinder);

    final headerBottomY = headerBox
        .localToGlobal(Offset(0, headerBox.size.height))
        .dy;
    final cardTopY = cardBox.localToGlobal(Offset.zero).dy;

    final gap = headerBottomY - cardTopY;

    // Expect at least 40 logical pixels of white-space
    expect(gap, greaterThanOrEqualTo(40.0),
        reason: 'Need more top white-space inside the card.');
  });
}
