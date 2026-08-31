import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:raid_compass/main.dart';

void main() {
  testWidgets('home screen is displayed', (tester) async {
    await tester.pumpWidget(const RaidCompassApp());

    expect(find.text('Raid Compass'), findsOneWidget);
    expect(find.text('レイド準備を、ひとつの場所で。'), findsOneWidget);
    expect(find.text('クイックアクセス'), findsOneWidget);
  });

  testWidgets('items page can be opened', (tester) async {
    await tester.pumpWidget(const RaidCompassApp());

    await tester.tap(find.text('アイテム').last);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 500));

    expect(find.byType(TextField), findsOneWidget);
    expect(find.text('例：LEDX、Salewa、M4A1'), findsOneWidget);
  });
}
