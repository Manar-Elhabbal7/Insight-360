import 'package:flutter_test/flutter_test.dart';
import 'package:news_app/main.dart';

void main() {
  testWidgets('Login screen displays expected elements', (
    WidgetTester tester,
  ) async {
    // Build our app and trigger a frame.
    await tester.pumpWidget(const NewsApp());

    // Verify that our welcome message is displayed.
    expect(find.text('Welcome Back'), findsOneWidget);
    expect(
      find.text('yLogin to stay updated with the latest news'),
      findsOneWidget,
    );

    // Verify that the login button is present.
    expect(find.text('Login'), findsOneWidget);

    // Verify that form fields are present by searching for hint text.
    expect(find.text('Email'), findsOneWidget);
    expect(find.text('Password'), findsOneWidget);
  });
}
