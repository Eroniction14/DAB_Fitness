import 'package:flutter/material.dart';

/// A bar pinned to the bottom of the screen that expands to show [child].
/// Use as `Scaffold.bottomSheet`. Keeps clear of the system navigation /
/// gesture bar.
class CollapsibleSheet extends StatefulWidget {
  /// Height of the closed bar, excluding the bottom safe-area inset.
  static const barHeight = 30.0;

  final String title;
  final TextStyle? titleStyle;
  final double expandedHeight;
  final Widget child;

  const CollapsibleSheet({
    super.key,
    required this.title,
    this.titleStyle,
    this.expandedHeight = 300,
    required this.child,
  });

  @override
  State<CollapsibleSheet> createState() => _CollapsibleSheetState();
}

class _CollapsibleSheetState extends State<CollapsibleSheet> {
  bool _open = false;

  static double _bottomInset(BuildContext context) {
    final view = View.of(context);
    return view.viewPadding.bottom / view.devicePixelRatio;
  }

  @override
  Widget build(BuildContext context) {
    final surface = Theme.of(context).colorScheme.surface;
    final arrow = Icon(_open ? Icons.arrow_drop_down : Icons.arrow_drop_up);

    return Material(
      elevation: 4,
      color: Colors.transparent,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          GestureDetector(
            onTap: () => setState(() => _open = !_open),
            child: Container(
              height: CollapsibleSheet.barHeight,
              width: double.infinity,
              decoration: const BoxDecoration(
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(30),
                  topRight: Radius.circular(30),
                ),
                gradient: LinearGradient(
                  colors: [Color(0xff00e0ff), Color(0xff095e79)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  arrow,
                  Text(widget.title, style: widget.titleStyle),
                  arrow,
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeOut,
            child: _open
                ? Container(
                    height: widget.expandedHeight,
                    color: surface,
                    child: widget.child,
                  )
                : const SizedBox(width: double.infinity),
          ),
          // Keep the bar above Android's navigation / gesture bar. Scaffold
          // zeroes MediaQuery padding for its bottom sheet, so read the
          // inset from the view itself.
          ColoredBox(
            color: surface,
            child: SizedBox(
              width: double.infinity,
              height: _bottomInset(context),
            ),
          ),
        ],
      ),
    );
  }
}
