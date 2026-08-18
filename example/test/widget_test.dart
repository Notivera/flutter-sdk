// This is a basic Flutter widget test.

import 'package:flutter_test/flutter_test.dart';

import 'package:notivera_flutter_example/main.dart';

void main() {
  testWidgets('Shows Notivera example UI', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Notivera'), findsOneWidget);
    expect(find.text('Initialize'), findsOneWidget);
  });
}
