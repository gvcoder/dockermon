import 'package:flutter_test/flutter_test.dart';
import 'package:dockermon/main.dart';

void main() {
  testWidgets('App initializes', (WidgetTester tester) async {
    await tester.pumpWidget(const DockerMonApp());
    expect(find.text('DockerMon'), findsOneWidget);
  });
}
