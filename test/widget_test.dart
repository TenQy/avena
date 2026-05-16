import 'package:flutter_test/flutter_test.dart';

import 'package:tienda/app.dart';

void main() {
  testWidgets('Shows initial phase zero screen', (WidgetTester tester) async {
    await tester.pumpWidget(const TiendaApp());

    expect(find.text('Tienda'), findsOneWidget);
    expect(find.text('Base del proyecto lista'), findsOneWidget);
    expect(
      find.text('Las funciones se agregarán en fases posteriores.'),
      findsOneWidget,
    );
  });
}
