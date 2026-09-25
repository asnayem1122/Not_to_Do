import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:not_to_do/core/widgets/bento_empty_state.dart';

void main() {
  testWidgets('BentoEmptyState renders correctly and calls onCtaTap', (tester) async {
    bool ctaTapped = false;
    
    await tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: BentoEmptyState(
            icon: Icons.inbox,
            title: 'No Items',
            subtitle: 'You have no items in your list.',
            ctaLabel: 'Add Item',
            onCtaTap: () {
              ctaTapped = true;
            },
          ),
        ),
      ),
    );

    expect(find.text('No Items'), findsOneWidget);
    expect(find.text('You have no items in your list.'), findsOneWidget);
    
    final ctaButton = find.text('Add Item');
    expect(ctaButton, findsOneWidget);
    
    await tester.tap(ctaButton);
    await tester.pumpAndSettle();
    
    expect(ctaTapped, isTrue);
  });
}
