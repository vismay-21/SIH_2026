import 'package:flutter_test/flutter_test.dart';

import 'package:mobile_app/main.dart';

void main() {
  testWidgets('placeholder navigation flow reaches customer home', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    expect(find.text('Continue'), findsOneWidget);

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Customer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();

    expect(find.text('Customer Home'), findsOneWidget);
    expect(find.text('Navigation 2'), findsOneWidget);
    expect(find.text('Navigation 3'), findsOneWidget);
    expect(find.text('Navigation 4'), findsOneWidget);

    await tester.tap(find.text('Navigation 4'));
    await tester.pump();
    expect(find.text('Customer Navigation 4'), findsOneWidget);
  });

  testWidgets('customer registration returns to login', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Customer'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Complete Registration'));
    await tester.pumpAndSettle();

    expect(find.text('Customer Login'), findsOneWidget);
  });

  testWidgets('worker flow reaches all placeholder destinations', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(const MyApp());

    await tester.tap(find.text('Continue'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Worker'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Register'));
    await tester.pumpAndSettle();
    await tester.tap(find.text('Complete Registration'));
    await tester.pumpAndSettle();
    expect(find.text('Worker Login'), findsOneWidget);

    await tester.tap(find.text('Login'));
    await tester.pumpAndSettle();
    expect(find.text('Worker Home'), findsOneWidget);

    for (final destination in [
      'Navigation 2',
      'Navigation 3',
      'Navigation 4',
    ]) {
      await tester.tap(find.text(destination));
      await tester.pump();
      expect(find.text('Worker $destination'), findsOneWidget);
    }
  });
}