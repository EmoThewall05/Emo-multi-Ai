import 'package:flutter_test/flutter_test.dart';
import 'package:emo_multi_ai/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const EmoMultiApp());
    expect(find.text('EmoMulti AI Studio'), findsOneWidget);
  });
}
