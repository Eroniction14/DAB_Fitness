import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dab_fitness/widgets/refreshable_list.dart';

void main() {
  var refreshes = 0;

  Widget list(
          {List<String> items = const [],
          bool loading = false,
          Object? error}) =>
      MaterialApp(
        home: Scaffold(
          body: RefreshableList<String>(
            items: items,
            isLoading: loading,
            error: error,
            onRefresh: () async => refreshes++,
            emptyMessage: 'Nothing here',
            itemBuilder: (_, item) => ListTile(title: Text(item)),
          ),
        ),
      );

  setUp(() => refreshes = 0);

  testWidgets('loading with no data shows a spinner', (tester) async {
    await tester.pumpWidget(list(loading: true));
    expect(find.byType(CircularProgressIndicator), findsOneWidget);
  });

  testWidgets('empty shows the message and can be pulled to refresh',
      (tester) async {
    await tester.pumpWidget(list());
    expect(find.text('Nothing here'), findsOneWidget);
    await tester.fling(find.text('Nothing here'), const Offset(0, 400), 1000);
    await tester.pumpAndSettle();
    expect(refreshes, 1);
  });

  testWidgets('error with no data offers Retry', (tester) async {
    await tester.pumpWidget(list(error: Exception('offline')));
    await tester.tap(find.text('Retry'));
    expect(refreshes, 1);
  });

  testWidgets('error with old data keeps the data and shows a banner',
      (tester) async {
    await tester.pumpWidget(list(items: ['a', 'b'], error: Exception('x')));
    expect(find.text('a'), findsOneWidget);
    expect(find.textContaining("Couldn't refresh"), findsOneWidget);
  });
}
