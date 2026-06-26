import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_smart_form/flutter_smart_form.dart';

void main() {
  Widget buildApp(Widget child) {
    return MaterialApp(
      home: Scaffold(
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: child,
        ),
      ),
    );
  }

  group('SmartTextFormField.email', () {
    testWidgets('renders with email defaults', (tester) async {
      await tester.pumpWidget(buildApp(
        SmartTextFormField.email(name: 'email'),
      ));

      expect(find.text('Email'), findsOneWidget);
      expect(find.byIcon(Icons.email_outlined), findsOneWidget);
    });

    testWidgets('validates invalid email on blur', (tester) async {
      await tester.pumpWidget(buildApp(
        SmartTextFormField.email(name: 'email'),
      ));

      final field = find.byType(TextFormField);
      await tester.enterText(field, 'notanemail');
      // Trigger blur
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Please enter a valid email address'), findsOneWidget);
    });

    testWidgets('accepts valid email', (tester) async {
      await tester.pumpWidget(buildApp(
        SmartTextFormField.email(name: 'email'),
      ));

      final field = find.byType(TextFormField);
      await tester.enterText(field, 'user@gmail.com');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.text('Please enter a valid email address'), findsNothing);
    });

    testWidgets('detects email typo', (tester) async {
      String? detectedSuggestion;
      await tester.pumpWidget(buildApp(
        SmartTextFormField.email(
          name: 'email',
          onTypoDetected: (s) => detectedSuggestion = s,
        ),
      ));

      final field = find.byType(TextFormField);
      await tester.enterText(field, 'user@gmial.com');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump(const Duration(milliseconds: 400));

      expect(detectedSuggestion, 'user@gmail.com');
    });
  });

  group('SmartTextFormField.phone', () {
    testWidgets('renders with phone defaults', (tester) async {
      await tester.pumpWidget(buildApp(
        SmartTextFormField.phone(name: 'phone'),
      ));

      expect(find.text('Phone'), findsOneWidget);
      expect(find.byIcon(Icons.phone_outlined), findsOneWidget);
    });
  });

  group('SmartTextFormField.creditCard', () {
    testWidgets('renders with credit card defaults', (tester) async {
      await tester.pumpWidget(buildApp(
        SmartTextFormField.creditCard(name: 'card'),
      ));

      expect(find.text('Card Number'), findsOneWidget);
      expect(find.byIcon(Icons.credit_card_outlined), findsOneWidget);
    });
  });

  group('SmartTextFormField.url', () {
    testWidgets('renders with URL defaults', (tester) async {
      await tester.pumpWidget(buildApp(
        SmartTextFormField.url(name: 'website'),
      ));

      expect(find.text('URL'), findsOneWidget);
      expect(find.byIcon(Icons.link_outlined), findsOneWidget);
    });
  });

  group('SmartTextFormField.password', () {
    testWidgets('renders with password defaults', (tester) async {
      await tester.pumpWidget(buildApp(
        SmartTextFormField.password(name: 'password'),
      ));

      expect(find.text('Password'), findsOneWidget);
      expect(find.byIcon(Icons.lock_outline), findsOneWidget);
    });

    testWidgets('validates minimum length', (tester) async {
      await tester.pumpWidget(buildApp(
        SmartTextFormField.password(name: 'password', minLength: 8),
      ));

      final field = find.byType(TextFormField);
      await tester.enterText(field, 'short');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pump(const Duration(milliseconds: 400));

      expect(find.textContaining('at least 8'), findsOneWidget);
    });

    testWidgets('validates uppercase requirement', (tester) async {
      await tester.pumpWidget(buildApp(
        SmartTextFormField.password(
          name: 'password',
          minLength: 1,
          requireUppercase: true,
        ),
      ));

      final field = find.byType(TextFormField);
      await tester.enterText(field, 'nouppercase');
      await tester.testTextInput.receiveAction(TextInputAction.done);
      await tester.pumpAndSettle();

      expect(find.text('Must contain an uppercase letter'), findsOneWidget);
    });
  });

  group('SmartTextFormField.numeric', () {
    testWidgets('renders with numeric defaults', (tester) async {
      await tester.pumpWidget(buildApp(
        SmartTextFormField.numeric(name: 'amount'),
      ));

      expect(find.text('Number'), findsOneWidget);
    });
  });

  group('SmartFormController integration', () {
    testWidgets('validates all fields via controller', (tester) async {
      final controller = SmartFormController();

      await tester.pumpWidget(buildApp(
        Column(
          children: [
            SmartTextFormField.email(
              name: 'email',
              formController: controller,
            ),
            SmartTextFormField.password(
              name: 'password',
              formController: controller,
            ),
          ],
        ),
      ));

      // Both empty — should fail
      expect(controller.validate(), isFalse);

      // Let shake animations settle before teardown
      await tester.pumpAndSettle();
    });
  });
}
