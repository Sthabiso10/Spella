import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:spella/ui/widgets/count_up_text.dart';

String _shown(WidgetTester tester) => tester.widget<Text>(find.byType(Text)).data!;

Widget _host(Widget child) => MaterialApp(home: Scaffold(body: child));

void main() {
  testWidgets('a plain figure appears at its value and does not roll', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_host(const CountUpText(value: 240, style: TextStyle())));

    expect(_shown(tester), '240');
    await tester.pumpAndSettle();
    expect(_shown(tester), '240');
  });

  testWidgets('a figure given a start rolls up to its value on arrival', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _host(const CountUpText(value: 240, from: 0, style: TextStyle())),
    );

    expect(_shown(tester), '0');

    await tester.pump(const Duration(milliseconds: 150));
    final int midway = int.parse(_shown(tester));
    expect(midway, greaterThan(0));
    expect(midway, lessThan(240));

    await tester.pumpAndSettle();
    expect(_shown(tester), '240');
  });

  testWidgets('a changed value rolls from what was already showing', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(_host(const CountUpText(value: 40, style: TextStyle())));
    await tester.pumpAndSettle();

    await tester.pumpWidget(_host(const CountUpText(value: 88, style: TextStyle())));
    await tester.pump(const Duration(milliseconds: 150));

    final int midway = int.parse(_shown(tester));
    expect(midway, greaterThan(40));
    expect(midway, lessThan(88));

    await tester.pumpAndSettle();
    expect(_shown(tester), '88');
  });

  testWidgets('large figures keep their thousands separators while rolling', (
    WidgetTester tester,
  ) async {
    await tester.pumpWidget(
      _host(const CountUpText(value: 12450, from: 0, style: TextStyle())),
    );
    await tester.pumpAndSettle();

    expect(_shown(tester), '12,450');
  });
}
