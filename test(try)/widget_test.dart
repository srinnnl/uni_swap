import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:uni_swap/view/login.dart';

void main() {
  testWidgets('renders the login screen', (tester) async {
    await tester.pumpWidget(const MaterialApp(home: LoginPage()));

    expect(find.text('UniSwap'), findsOneWidget);
    expect(find.text('Welcome back'), findsOneWidget);
  });
}
