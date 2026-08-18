import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:notivera_flutter_example/main.dart';

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('example app loads', (WidgetTester tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('Notivera'), findsOneWidget);
  });
}
