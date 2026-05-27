import 'package:explore_index/app.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  testWidgets('App smoke test — renders without crashing', (WidgetTester tester) async {
    await tester.pumpWidget(
      const ProviderScope(child: ExploreIndexApp()),
    );
    expect(find.byType(MaterialApp), findsOneWidget);
  });
}
