// This is a basic Flutter widget test.
//
// To perform an interaction with a widget in your test, use the WidgetTester
// utility in the flutter_test package. For example, you can send tap and scroll
// gestures. You can also use WidgetTester to find child widgets in the widget
// tree, read text, and verify that the values of widget properties are correct.

import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:meow/main.dart';
import 'package:meow/ui/page/common/login_page.dart';
import 'package:meow/util/store.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  testWidgets('默认展示登录页', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await Store().init();

    await tester.pumpWidget(const ProviderScope(child: MyApp()));
    await tester.pumpAndSettle();

    expect(find.byType(LoginPage), findsOneWidget);
  });
}
