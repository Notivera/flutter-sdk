import 'package:flutter_test/flutter_test.dart';
import 'package:notivera_flutter_example/main.dart';

void main() {
  testWidgets('Shows Home and Offline tabs', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    await tester.pump();

    expect(find.text('Home'), findsWidgets);
    expect(find.text('Offline'), findsOneWidget);
    expect(find.text('Select an experience'), findsOneWidget);
    expect(find.textContaining('Notifications (4)'), findsOneWidget);
  });
}
