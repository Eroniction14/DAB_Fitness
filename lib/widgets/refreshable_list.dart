import 'package:flutter/material.dart';

import 'package:dab_fitness/config/theme.dart';
import 'package:dab_fitness/widgets/empty_state.dart';
import 'package:dab_fitness/widgets/skeleton.dart';

/// A pull-to-refresh list with skeleton loading, empty, and error (with
/// Retry) states. The empty and error states are scrollable too, so pulling
/// down still refreshes them.
class RefreshableList<T> extends StatelessWidget {
  final List<T> items;
  final bool isLoading;
  final Object? error;
  final Future<void> Function() onRefresh;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final String emptyTitle;
  final String? emptyHint;
  final IconData emptyIcon;
  final Widget? emptyAction;
  final EdgeInsetsGeometry padding;

  /// Height of each skeleton placeholder row while loading.
  final double skeletonHeight;

  const RefreshableList({
    super.key,
    required this.items,
    required this.isLoading,
    required this.error,
    required this.onRefresh,
    required this.itemBuilder,
    required this.emptyTitle,
    this.emptyHint,
    this.emptyIcon = Icons.inbox_outlined,
    this.emptyAction,
    this.padding = const EdgeInsets.symmetric(
        horizontal: AppSpacing.screen, vertical: AppSpacing.lg),
    this.skeletonHeight = 84,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && items.isEmpty) {
      return SkeletonList(itemHeight: skeletonHeight, padding: padding);
    }

    final Widget content;
    if (items.isEmpty) {
      content = _Fill(
        child: error != null
            ? EmptyState(
                icon: Icons.cloud_off_outlined,
                title: "Couldn't load this",
                hint: 'Check your connection and try again.',
                isError: true,
                action: OutlinedButton.icon(
                  onPressed: onRefresh,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Retry'),
                ),
              )
            : EmptyState(
                icon: emptyIcon,
                title: emptyTitle,
                hint: emptyHint,
                action: emptyAction,
              ),
      );
    } else {
      content = ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding,
        // A refresh that failed while showing older data gets a banner.
        itemCount: items.length + (error != null ? 1 : 0),
        separatorBuilder: (_, __) => const SizedBox(height: AppSpacing.md),
        itemBuilder: (context, index) {
          if (error != null) {
            if (index == 0) return const _StaleBanner();
            index--;
          }
          return itemBuilder(context, items[index]);
        },
      );
    }
    return RefreshIndicator(onRefresh: onRefresh, child: content);
  }
}

/// Fills the viewport with [child] centred, but can still be pulled.
class _Fill extends StatelessWidget {
  final Widget child;
  const _Fill({required this.child});

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Center(child: child),
          ),
        ],
      ),
    );
  }
}

class _StaleBanner extends StatelessWidget {
  const _StaleBanner();

  @override
  Widget build(BuildContext context) {
    final scheme = context.colors;
    return Container(
      padding: const EdgeInsets.all(AppSpacing.md),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: AppRadius.inputAll,
      ),
      child: Row(
        children: [
          Icon(Icons.cloud_off_outlined, color: scheme.onErrorContainer),
          const SizedBox(width: AppSpacing.sm),
          Expanded(
            child: Text("Couldn't refresh. Showing the last loaded data.",
                style: context.textStyles.bodyMedium
                    ?.copyWith(color: scheme.onErrorContainer)),
          ),
        ],
      ),
    );
  }
}
