import 'package:flutter_test/flutter_test.dart';
import 'package:sieda/main.dart';

void main() {
  testWidgets('SiEdaApp should render without errors', (WidgetTester tester) async {
    await tester.pumpWidget(const SiEdaApp());
    expect(find.byType(SiEdaApp), findsOneWidget);
  });
}
