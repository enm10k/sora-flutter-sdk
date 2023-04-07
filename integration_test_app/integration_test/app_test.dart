import 'package:flutter_test/flutter_test.dart';
import 'package:integration_test/integration_test.dart';
import 'package:integration_test_app/main.dart' as app;

void main() {
  IntegrationTestWidgetsFlutterBinding.ensureInitialized();

  group('', () {
    testWidgets('',
        (tester) async {
      app.main();
      await tester.pumpAndSettle();
    });
  });
}
