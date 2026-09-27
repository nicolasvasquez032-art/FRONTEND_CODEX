import 'package:flutter_test/flutter_test.dart';
import 'package:talentmatch/main.dart';

void main() {
  testWidgets('shows EmpleaIA home', (tester) async {
    await tester.pumpWidget(const MyApp());
    expect(find.text('EmpleaIA'), findsOneWidget);
  });
}
