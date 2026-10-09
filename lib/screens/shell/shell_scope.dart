import 'package:flutter/widgets.dart';

/// Lets a tab inside a navigation shell switch to another tab.
class ShellScope extends InheritedWidget {
  final int currentTab;
  final ValueChanged<int> selectTab;

  const ShellScope({
    super.key,
    required this.currentTab,
    required this.selectTab,
    required super.child,
  });

  /// The nearest shell, or null when a tab screen is shown on its own
  /// (e.g. pushed via its route).
  static ShellScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellScope>();

  @override
  bool updateShouldNotify(ShellScope old) => old.currentTab != currentTab;
}
