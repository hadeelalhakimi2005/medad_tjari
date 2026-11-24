import 'package:flutter_test/flutter_test.dart';
import 'package:medad_tjari/main.dart';

void main() {
  testWidgets('App loads smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const MedadTjariApp());
    expect(find.byType(MedadTjariApp), findsOneWidget);
  });
}
