import 'package:flutter/material.dart';

import 'package:dab_fitness/config/theme.dart';
import 'package:dab_fitness/models/booking.dart';
import 'package:dab_fitness/widgets/refreshable_list.dart';

/// Bookings in Today / Upcoming / Past sections (see [groupBookings]), with
/// pull-to-refresh and empty/error states. Past is collapsed until tapped
/// and its sessions are muted.
class GroupedBookingsList extends StatefulWidget {
  final List<Booking> bookings;
  final bool isLoading;
  final Object? error;
  final Future<void> Function() onRefresh;

  /// Builds the tile for one booking (title/detail differ for users and
  /// trainers). [muted] is true for past sessions.
  final Widget Function(BuildContext context, Booking booking, bool muted)
      tileBuilder;

  final String emptyTitle;
  final String? emptyHint;
  final Widget? emptyAction;

  const GroupedBookingsList({
    super.key,
    required this.bookings,
    required this.isLoading,
    required this.error,
    required this.onRefresh,
    required this.tileBuilder,
    required this.emptyTitle,
    this.emptyHint,
    this.emptyAction,
  });

  @override
  State<GroupedBookingsList> createState() => _GroupedBookingsListState();
}

/// A section header or a booking.
sealed class _Row {}

class _Header extends _Row {
  final String title;
  final int count;
  final bool collapsible;
  _Header(this.title, this.count, {this.collapsible = false});
}

class _Item extends _Row {
  final Booking booking;
  final bool past;
  _Item(this.booking, {this.past = false});
}

class _GroupedBookingsListState extends State<GroupedBookingsList> {
  bool _showPast = false;

  @override
  Widget build(BuildContext context) {
    final groups = groupBookings(widget.bookings, DateTime.now());
    final rows = <_Row>[
      if (groups.today.isNotEmpty) ...[
        _Header('Today', groups.today.length),
        for (final b in groups.today) _Item(b),
      ],
      if (groups.upcoming.isNotEmpty) ...[
        _Header('Upcoming', groups.upcoming.length),
        for (final b in groups.upcoming) _Item(b),
      ],
      if (groups.past.isNotEmpty) ...[
        _Header('Past', groups.past.length, collapsible: true),
        if (_showPast)
          for (final b in groups.past) _Item(b, past: true),
      ],
    ];

    return RefreshableList<_Row>(
      items: rows,
      isLoading: widget.isLoading,
      error: widget.error,
      onRefresh: widget.onRefresh,
      emptyIcon: Icons.event_available_outlined,
      emptyTitle: widget.emptyTitle,
      emptyHint: widget.emptyHint,
      emptyAction: widget.emptyAction,
      itemBuilder: (context, row) => switch (row) {
        _Header(:final title, :final count, :final collapsible) =>
          _SectionHeader(
            title: title,
            count: count,
            expanded: collapsible ? _showPast : null,
            onTap: collapsible
                ? () => setState(() => _showPast = !_showPast)
                : null,
          ),
        _Item(:final booking, :final past) => KeyedSubtree(
            key: ValueKey(booking.key),
            child: widget.tileBuilder(context, booking, past),
          ),
      },
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  final int count;

  /// Null for headers that can't collapse.
  final bool? expanded;
  final VoidCallback? onTap;

  const _SectionHeader(
      {required this.title, required this.count, this.expanded, this.onTap});

  @override
  Widget build(BuildContext context) {
    final secondary = context.appColors.textSecondary;
    final label = Row(
      children: [
        Expanded(
          child: Text('$title · $count',
              style: context.textStyles.titleSmall?.copyWith(color: secondary)),
        ),
        if (expanded != null)
          Icon(expanded! ? Icons.expand_less : Icons.expand_more,
              color: secondary),
      ],
    );
    final padded = Padding(
      padding: const EdgeInsets.only(top: AppSpacing.sm),
      child: ConstrainedBox(
        constraints: const BoxConstraints(minHeight: AppSpacing.tapTarget),
        child: Align(alignment: Alignment.centerLeft, child: label),
      ),
    );
    if (onTap == null) {
      return Semantics(header: true, child: padded);
    }
    return Semantics(
      header: true,
      button: true,
      expanded: expanded,
      label: '$title, $count sessions, ${expanded! ? 'hide' : 'show'}',
      excludeSemantics: true,
      child: InkWell(
        borderRadius: AppRadius.inputAll,
        onTap: onTap,
        child: padded,
      ),
    );
  }
}
