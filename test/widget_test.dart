import 'package:flutter_test/flutter_test.dart';

import 'package:avena/app.dart';

void main() {
  testWidgets('Shows phase one navigation', (WidgetTester tester) async {
    await tester.pumpWidget(const TiendaApp());

    expect(find.text('Dashboard'), findsWidgets);
    expect(find.text('Ventas'), findsOneWidget);
    expect(find.text('Inventarios'), findsOneWidget);
    expect(find.text('Otros'), findsOneWidget);
  });
}
