import 'package:flutter/material.dart';

import 'package:dab_fitness/config/theme.dart';
import 'package:dab_fitness/models/trainer.dart';
import 'package:dab_fitness/screens/trainers/book_trainer.dart';
import 'package:dab_fitness/widgets/app_card.dart';
import 'package:dab_fitness/widgets/busy_button.dart';
import 'package:dab_fitness/widgets/rating_stars.dart';

/// A trainer's profile: collapsing photo header, About / Experience /
/// Contact cards and a pinned "Book a session" button.
class TrainerDetail extends StatefulWidget {
  final Trainer trainer;
  const TrainerDetail(this.trainer, {super.key});

  @override
  State<TrainerDetail> createState() => _TrainerDetailState();
}

class _TrainerDetailState extends State<TrainerDetail> {
  bool _expandText = false;
  bool _isBooking = false;

  Trainer get trainer => widget.trainer;

  Future<void> _openBooking() => bookTrainer(context, trainer, onBusy: (busy) {
        if (mounted) setState(() => _isBooking = busy);
      });

  @override
  Widget build(BuildContext context) {
    final text = context.textStyles;
    final secondary = context.appColors.textSecondary;
    final years = trainer.experience;

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          SliverAppBar(
            expandedHeight: 320,
            pinned: true,
            stretch: true,
            // A tonal circle keeps Back visible on the photo and on the
            // collapsed bar alike.
            leading: Padding(
              padding: const EdgeInsets.all(AppSpacing.xs),
              child: IconButton.filledTonal(
                tooltip: 'Back',
                icon: const BackButtonIcon(),
                onPressed: () => Navigator.of(context).maybePop(),
              ),
            ),
            flexibleSpace: FlexibleSpaceBar(
              stretchModes: const [StretchMode.zoomBackground],
              background: Image.asset(trainer.image, fit: BoxFit.cover),
            ),
          ),
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.lg,
                AppSpacing.screen, AppSpacing.xl),
            sliver: SliverList.list(
              children: [
                Text(trainer.name, style: text.titleLarge),
                const SizedBox(height: AppSpacing.xs),
                Row(
                  children: [
                    Flexible(
                      child: Text(trainer.speciality,
                          style: text.bodyLarge?.copyWith(color: secondary)),
                    ),
                    const SizedBox(width: AppSpacing.md),
                    RatingStars(rating: trainer.rating),
                  ],
                ),
                const SizedBox(height: AppSpacing.xl),
                _InfoCard(
                  title: 'About',
                  child: InkWell(
                    onTap: trainer.description.length > 120
                        ? () => setState(() => _expandText = !_expandText)
                        : null,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          trainer.description,
                          maxLines: _expandText ? null : 4,
                          overflow: _expandText ? null : TextOverflow.ellipsis,
                          style: text.bodyMedium?.copyWith(color: secondary),
                        ),
                        if (trainer.description.length > 120)
                          Padding(
                            padding: const EdgeInsets.only(top: AppSpacing.sm),
                            child: Text(_expandText ? 'Show less' : 'Read more',
                                style: text.labelLarge
                                    ?.copyWith(color: context.colors.primary)),
                          ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _InfoCard(
                  title: 'Experience',
                  child: Column(
                    children: [
                      _InfoRow(
                          icon: Icons.workspace_premium_outlined,
                          label: 'Experience',
                          value: '$years year${years == 1 ? '' : 's'}'),
                      if (trainer.age.isNotEmpty)
                        _InfoRow(
                            icon: Icons.cake_outlined,
                            label: 'Age',
                            value: trainer.age),
                    ],
                  ),
                ),
                const SizedBox(height: AppSpacing.md),
                _InfoCard(
                  title: 'Contact',
                  child: Column(
                    children: [
                      if (trainer.number.isNotEmpty)
                        _InfoRow(
                            icon: Icons.phone_outlined,
                            label: 'Phone',
                            value: trainer.number),
                      if (trainer.email.isNotEmpty)
                        _InfoRow(
                            icon: Icons.email_outlined,
                            label: 'Email',
                            value: trainer.email),
                      if (trainer.address.isNotEmpty)
                        _InfoRow(
                            icon: Icons.location_on_outlined,
                            label: 'City',
                            value: trainer.address),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
      bottomNavigationBar: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(AppSpacing.screen, AppSpacing.sm,
              AppSpacing.screen, AppSpacing.lg),
          child: BusyFilledButton(
              label: 'Book a session',
              busy: _isBooking,
              onPressed: _openBooking),
        ),
      ),
    );
  }
}

class _InfoCard extends StatelessWidget {
  final String title;
  final Widget child;
  const _InfoCard({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: context.textStyles.titleMedium),
          const SizedBox(height: AppSpacing.sm),
          child,
        ],
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _InfoRow(
      {required this.icon, required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    final secondary = context.appColors.textSecondary;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: AppSpacing.xs),
      child: Row(
        children: [
          Icon(icon, size: 20, color: secondary),
          const SizedBox(width: AppSpacing.md),
          Text(label,
              style: context.textStyles.bodyMedium?.copyWith(color: secondary)),
          const SizedBox(width: AppSpacing.md),
          Expanded(
            child: Text(value,
                textAlign: TextAlign.end, style: context.textStyles.bodyMedium),
          ),
        ],
      ),
    );
  }
}
