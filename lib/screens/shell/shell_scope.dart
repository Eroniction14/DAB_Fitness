import 'package:flutter/widgets.dart';

/// Lets a tab inside a navigation shell switch to another tab, and tells it
/// which tab index holds what (the user and trainer shells differ).
class ShellScope extends InheritedWidget {
  final int currentTab;
  final ValueChanged<int> selectTab;
  final int bookingsTab;
  final int profileTab;

  /// Null in the trainer shell, which has no Trainings tab.
  final int? trainingsTab;

  const ShellScope({
    super.key,
    required this.currentTab,
    required this.selectTab,
    required this.bookingsTab,
    required this.profileTab,
    this.trainingsTab,
    required super.child,
  });

  /// The nearest shell, or null when a tab screen is shown on its own
  /// (e.g. pushed via its route).
  static ShellScope? maybeOf(BuildContext context) =>
      context.dependOnInheritedWidgetOfExactType<ShellScope>();

  @override
  bool updateShouldNotify(ShellScope old) => old.currentTab != currentTab;
}
