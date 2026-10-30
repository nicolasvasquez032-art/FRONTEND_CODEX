import 'package:flutter_test/flutter_test.dart';
import 'package:talentmatch/main.dart';

void main() {
  testWidgets('shows TalentMatch splash and home', (tester) async {
    await tester.pumpWidget(const TalentMatchApp());
    expect(find.text('TalentMatch'), findsOneWidget);
  });
}
