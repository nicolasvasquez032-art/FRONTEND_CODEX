import 'package:flutter_test/flutter_test.dart';
import 'package:talentmatch/main.dart';

void main() {
  testWidgets('shows TalentMatch home', (tester) async {
    await tester.pumpWidget(const TalentMatchApp());
    expect(find.text('EmpleaIA'), findsOneWidget);
  });
}
