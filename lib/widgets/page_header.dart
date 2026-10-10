import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:dab_fitness/config/theme.dart';
import 'package:dab_fitness/providers/database_model.dart';
import 'package:dab_fitness/screens/shell/shell_scope.dart';
import 'package:dab_fitness/widgets/initials_avatar.dart';

/// The compact header at the top of every tab: title and optional subtitle
/// on the left, the signed-in person's avatar on the right (opens the
/// Profile tab). Shows a back button instead when the screen was pushed.
class PageHeader extends StatelessWidget {
  final String title;
  final String? subtitle;

  /// Show the profile avatar on the right (off on the Profile tab itself).
  final bool showAvatar;

  const PageHeader({
    super.key,
    required this.title,
    this.subtitle,
    this.showAvatar = true,
  });

  @override
  Widget build(BuildContext context) {
    final canPop = ModalRoute.of(context)?.canPop ?? false;
    return SafeArea(
      bottom: false,
      child: Padding(
        padding: EdgeInsets.fromLTRB(canPop ? AppSpacing.xs : AppSpacing.screen,
            AppSpacing.lg, AppSpacing.screen, AppSpacing.sm),
        child: Row(
          children: [
            if (canPop) const BackButton(),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Semantics(
                    header: true,
                    child: Text(title,
                        style: context.textStyles.titleLarge,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                  ),
                  if (subtitle != null)
                    Text(subtitle!,
                        style: context.textStyles.bodyMedium
                            ?.copyWith(color: context.appColors.textSecondary),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
            if (showAvatar) ...[
              const SizedBox(width: AppSpacing.md),
              const ProfileAvatarButton(),
            ],
          ],
        ),
      ),
    );
  }
}

/// The signed-in person's initials. Opens the Profile tab of the current
/// shell; hidden when there is no shell or no profile.
class ProfileAvatarButton extends StatelessWidget {
  const ProfileAvatarButton({super.key});

  @override
  Widget build(BuildContext context) {
    final profile = context.watch<DatabaseModel>().profile;
    final shell = ShellScope.maybeOf(context);
    if (profile == null || shell == null) return const SizedBox.shrink();
    return Tooltip(
      message: 'Profile',
      child: InkResponse(
        onTap: () => shell.selectTab(shell.profileTab),
        radius: AppSpacing.tapTarget / 2,
        child: SizedBox.square(
          dimension: AppSpacing.tapTarget,
          child: Center(child: InitialsAvatar(name: profile.name, radius: 22)),
        ),
      ),
    );
  }
}
