import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:frontend/app.dart';

void main() {
  testWidgets('shows app foundation', (WidgetTester tester) async {
    await tester.pumpWidget(const ProviderScope(child: MaraAttendanceApp()));

    expect(find.byType(MaraAttendanceApp), findsOneWidget);
  });
}
