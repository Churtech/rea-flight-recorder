import 'package:flutter_test/flutter_test.dart';
import 'package:rea_flight_recorder_example/main.dart';

void main() {
  testWidgets('Renders Flight Recorder Demo smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Flight Recorder Demo'), findsOneWidget);
    expect(find.text('In-App Flight Recorder'), findsOneWidget);
  });
}
