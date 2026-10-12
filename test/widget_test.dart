import 'package:flutter_test/flutter_test.dart';
import 'package:life_reminder/app/app.dart';
import 'package:sqflite_common_ffi/sqflite_ffi.dart';

void main() {
  setUpAll(() {
    sqfliteFfiInit();
    databaseFactory = databaseFactoryFfi;
  });

  testWidgets('LifeReminderApp smoke test', (WidgetTester tester) async {
    await tester.pumpWidget(const LifeReminderApp());
    await tester.pumpAndSettle();
    expect(find.text('Life Reminder'), findsNothing); // Nav bar / screen check
  });
}
