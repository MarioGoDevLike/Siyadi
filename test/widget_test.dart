import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:siyadi/app.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  testWidgets('SIYADI shell shows brand and bottom destinations', (tester) async {
    await tester.pumpWidget(
      const ProviderScope(
        child: SiyadiApp(),
      ),
    );
    await tester.pumpAndSettle();

    // Without Firebase initialized, auth gate treats session as ready (test mode).
    expect(find.text('SIYADI'), findsOneWidget);
    expect(find.text('Home'), findsWidgets);
    expect(find.text('Map'), findsOneWidget);
    expect(find.text('Market'), findsOneWidget);
    expect(find.text('Profile'), findsOneWidget);

    await tester.tap(find.text('Map'));
    await tester.pumpAndSettle();
    expect(find.textContaining('Hunting map'), findsOneWidget);

    await tester.tap(find.byTooltip('Create'));
    await tester.pumpAndSettle();
    expect(find.text('Social post'), findsOneWidget);
    expect(find.text('Field report'), findsOneWidget);
    expect(find.text('Propose location'), findsOneWidget);
  });
}
