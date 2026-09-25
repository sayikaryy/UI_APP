import 'package:flutter_test/flutter_test.dart';
import 'package:bookverse_project/main.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('BookVerse App smoke test', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await tester.pumpWidget(const BookVerseApp());
    await tester.pump(const Duration(seconds: 2));
    expect(find.byType(BookVerseApp), findsOneWidget);
  });
}
