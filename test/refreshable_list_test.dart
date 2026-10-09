import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:dab_fitness/config/theme.dart';
import 'package:dab_fitness/widgets/refreshable_list.dart';
import 'package:dab_fitness/widgets/skeleton.dart';

void main() {
  var refreshes = 0;

  Widget list(
          {List<String> items = const [],
          bool loading = false,
          Object? error}) =>
      MaterialApp(
        theme: AppTheme.light,
        home: Scaffold(
          body: RefreshableList<String>(
            items: items,
            isLoading: loading,
            error: error,
            onRefresh: () async => refreshes++,
            emptyTitle: 'Nothing here',
            emptyHint: 'Add something.',
            itemBuilder: (_, item) => ListTile(title: Text(item)),
          ),
        ),
      );

  setUp(() => refreshes = 0);

  testWidgets('loading with no data shows skeleton rows, not a spinner',
      (tester) async {
    await tester.pumpWidget(list(loading: true));
    expect(find.byType(SkeletonList), findsOneWidget);
    expect(find.byType(CircularProgressIndicator), findsNothing);
  });

  testWidgets('empty shows the message and can be pulled to refresh',
      (tester) async {
    await tester.pumpWidget(list());
    expect(find.text('Nothing here'), findsOneWidget);
    expect(find.text('Add something.'), findsOneWidget);
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
