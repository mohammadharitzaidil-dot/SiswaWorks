import 'package:flutter_test/flutter_test.dart';
import 'package:siswaworks/main.dart';

void main() {
  testWidgets('SiswaWorks renders its initial screen', (tester) async {
    // Pump the real app widget without invoking Firebase bootstrap in main().
    await tester.pumpWidget(const MainApp());

    expect(find.text('SiswaWorks Firebase Test'), findsOneWidget);
    expect(tester.takeException(), isNull);
  });
}
