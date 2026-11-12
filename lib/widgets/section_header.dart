import 'package:flutter/material.dart';

import '../core/haptics.dart';
import '../core/tokens.dart';
import '../core/typography.dart';

/// Consistent section header row: h2 title on the left + optional "Show all" action.
class SectionHeader extends StatelessWidget {
  const SectionHeader({
    super.key,
    required this.title,
    this.actionLabel = 'Show all',
    this.onActionTap,
  });

  final String title;
  final String? actionLabel;
  final VoidCallback? onActionTap;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: OrbitTokens.screenPadding),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Expanded(
            child: Text(
              title,
              style: OrbitTypography.h2,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (actionLabel != null && onActionTap != null)
            Semantics(
              button: true,
              label: '$actionLabel for $title',
              child: GestureDetector(
                behavior: HitTestBehavior.opaque,
                onTap: () {
                  OrbitHaptics.selection();
                  onActionTap!();
                },
                child: ConstrainedBox(
                  constraints: const BoxConstraints(
                    minHeight: OrbitTokens.minTouchTarget,
                  ),
                  child: Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: const EdgeInsets.only(left: OrbitTokens.space12),
                      child: Text(
                        actionLabel!,
                        style: OrbitTypography.bodyS.copyWith(
                          color: OrbitTokens.textSecondary,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}
