import 'package:flutter/material.dart';

/// A pull-to-refresh list with loading, error (with Retry) and empty states.
/// The empty and error states are scrollable too, so pulling down still
/// refreshes them.
class RefreshableList<T> extends StatelessWidget {
  final List<T> items;
  final bool isLoading;
  final Object? error;
  final Future<void> Function() onRefresh;
  final Widget Function(BuildContext context, T item) itemBuilder;
  final String emptyMessage;
  final IconData emptyIcon;
  final EdgeInsetsGeometry? padding;

  const RefreshableList({
    super.key,
    required this.items,
    required this.isLoading,
    required this.error,
    required this.onRefresh,
    required this.itemBuilder,
    required this.emptyMessage,
    this.emptyIcon = Icons.inbox_outlined,
    this.padding,
  });

  @override
  Widget build(BuildContext context) {
    if (isLoading && items.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    final Widget content;
    if (items.isEmpty) {
      content = error != null
          ? _FillMessage(
              icon: Icons.cloud_off,
              message: "Couldn't load this. Check your connection.",
              action: OutlinedButton.icon(
                onPressed: onRefresh,
                icon: const Icon(Icons.refresh),
                label: const Text('Retry'),
              ),
            )
          : _FillMessage(icon: emptyIcon, message: emptyMessage);
    } else {
      content = ListView.builder(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: padding,
        // A refresh that failed while showing older data gets a banner.
        itemCount: items.length + (error != null ? 1 : 0),
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

/// A centred icon and message that fills the viewport but can still be
/// pulled to refresh.
class _FillMessage extends StatelessWidget {
  final IconData icon;
  final String message;
  final Widget? action;
  const _FillMessage({required this.icon, required this.message, this.action});

  @override
  Widget build(BuildContext context) {
    final color = Theme.of(context).colorScheme.outline;
    return LayoutBuilder(
      builder: (context, constraints) => ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        children: [
          ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Padding(
              padding: const EdgeInsets.all(24),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(icon, size: 48, color: color),
                  const SizedBox(height: 12),
                  Text(message,
                      textAlign: TextAlign.center,
                      style: TextStyle(fontSize: 16, color: color)),
                  if (action != null) ...[
                    const SizedBox(height: 12),
                    action!,
                  ],
                ],
              ),
            ),
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
    final scheme = Theme.of(context).colorScheme;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 15, vertical: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: scheme.errorContainer,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text("Couldn't refresh. Showing the last loaded data.",
          style: TextStyle(color: scheme.onErrorContainer)),
    );
  }
}
