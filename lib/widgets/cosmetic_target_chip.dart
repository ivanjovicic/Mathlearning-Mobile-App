import 'package:flutter/material.dart';

import '../models/cosmetic_target.dart';
import 'cosmetic_visuals.dart';

class CosmeticTargetChip extends StatelessWidget {
  const CosmeticTargetChip({
    super.key,
    required this.target,
    this.compact = false,
    this.maxWidth,
  });

  final CosmeticTarget target;
  final bool compact;
  final double? maxWidth;

  @override
  Widget build(BuildContext context) {
    final color = CosmeticVisuals.rarityColor(target.targetRarity);
    final progress =
        '${target.targetFragmentsOwned}/${target.targetFragmentsRequired}';
    final label = compact
        ? 'Chasing ${target.displayName}'
        : 'Chasing ${target.displayName} $progress';

    return Tooltip(
      message: '${target.displayName} $progress',
      child: ConstrainedBox(
        constraints: BoxConstraints(maxWidth: maxWidth ?? double.infinity),
        child: Container(
          key: const Key('cosmetic_target_chip'),
          padding: EdgeInsets.symmetric(
            horizontal: compact ? 7 : 9,
            vertical: compact ? 3 : 5,
          ),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withValues(alpha: 0.42)),
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: [
              SizedBox(
                width: compact ? 12 : 14,
                height: compact ? 12 : 14,
                child: CircularProgressIndicator(
                  value: target.progressValue,
                  strokeWidth: 2,
                  color: color,
                  backgroundColor: color.withValues(alpha: 0.18),
                ),
              ),
              const SizedBox(width: 5),
              Flexible(
                child: Text(
                  label,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(
                    color: color,
                    fontWeight: FontWeight.w900,
                    fontSize: compact ? 10 : null,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
