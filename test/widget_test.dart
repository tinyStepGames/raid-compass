import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raid_compass/main.dart';

void main() {
  testWidgets('shows the Raid Compass home screen', (tester) async {
    await tester.pumpWidget(const RaidCompassApp());

    expect(find.text('Raid Compass'), findsOneWidget);
    expect(find.byType(NavigationBar), findsOneWidget);
    expect(find.byIcon(Icons.explore_outlined), findsOneWidget);
  });

  testWidgets('shows five navigation destinations', (tester) async {
    await tester.pumpWidget(const RaidCompassApp());

    expect(find.byType(NavigationDestination), findsNWidgets(5));
  });
}
