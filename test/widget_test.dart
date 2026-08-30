import 'package:flutter_test/flutter_test.dart';
import 'package:raid_compass/main.dart';

void main() {
  testWidgets('Raid Compassのホーム画面を表示できる', (tester) async {
    await tester.pumpWidget(const RaidCompassApp());

    expect(find.text('Raid Compass'), findsOneWidget);
    expect(find.text('レイド準備を、ひとつの場所で。'), findsOneWidget);
    expect(find.text('クイックアクセス'), findsOneWidget);
  });

  testWidgets('アイテム画面へ移動できる', (tester) async {
    await tester.pumpWidget(const RaidCompassApp());

    await tester.tap(find.text('アイテム').last);
    await tester.pumpAndSettle();

    expect(find.text('アイテム名を入力'), findsOneWidget);
    expect(find.text('アイテムデータはまだありません'), findsOneWidget);
  });
}
