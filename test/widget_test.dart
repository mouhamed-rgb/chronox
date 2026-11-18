import 'package:flutter_test/flutter_test.dart';
import 'package:chronox/main.dart';

void main() {
  testWidgets('CHRONOX home app starts', (tester) async {
    await tester.pumpWidget(const ChronoxApp());
    expect(find.text('CHRONOX'), findsOneWidget);
  });
}
