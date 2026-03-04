import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../theme/astrax_theme.dart';

class LeaderboardScopeSelector extends StatelessWidget {
  final String selectedScope;
  final int? schoolId;
  final int? facultyId;
  final ValueChanged<String> onChanged;

  const LeaderboardScopeSelector({
    super.key,
    required this.selectedScope,
    required this.schoolId,
    required this.facultyId,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: AstraXTheme.panel.withValues(alpha: 0.7),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: Colors.white10),
      ),
      child: Row(
        children: [
          _buildItem(context, "global", enabled: true),
          const SizedBox(width: 6),
          _buildItem(context, "school", enabled: schoolId != null),
          const SizedBox(width: 6),
          _buildItem(context, "faculty", enabled: facultyId != null),
          const SizedBox(width: 6),
          _buildItem(context, "friends", enabled: true),
        ],
      ),
    );
  }

  Widget _buildItem(
    BuildContext context,
    String scope, {
    required bool enabled,
  }) {
    final isSelected = selectedScope == scope;

    final activeGradient = LinearGradient(
      colors: [
        AstraXTheme.neonBlue.withValues(alpha: 0.24),
        AstraXTheme.neonPurple.withValues(alpha: 0.14),
      ],
      begin: Alignment.topLeft,
      end: Alignment.bottomRight,
    );

    return Expanded(
      child: GestureDetector(
        behavior: HitTestBehavior.opaque,
        onTap: enabled
            ? () => onChanged(scope)
            : () => _showDisabledMessage(context, scope),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 220),
          curve: Curves.easeOutCubic,
          padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
          decoration: BoxDecoration(
            gradient: isSelected ? activeGradient : null,
            color: isSelected ? null : Colors.transparent,
            borderRadius: BorderRadius.circular(999),
            border: Border.all(
              color: enabled
                  ? (isSelected
                        ? AstraXTheme.neonBlue.withValues(alpha: 0.8)
                        : Colors.white10)
                  : Colors.white10,
            ),
          ),
          child: Center(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                if (!enabled)
                  const Padding(
                    padding: EdgeInsets.only(right: 4),
                    child: Icon(Icons.lock, size: 14, color: Colors.white24),
                  ),
                Flexible(
                  child: Text(
                    scope.toUpperCase(),
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(
                      fontWeight: FontWeight.w800,
                      fontSize: 12.5,
                      letterSpacing: 0.2,
                      color: enabled
                          ? (isSelected
                                ? AstraXTheme.textPrimary
                                : AstraXTheme.textSecondary)
                          : Colors.white24,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _showDisabledMessage(BuildContext context, String scope) {
    final message = scope == "school"
        ? "Add your school to unlock this leaderboard."
        : "Add your faculty to unlock this leaderboard.";

    showModalBottomSheet(
      context: context,
      backgroundColor: const Color(0xFF0F172A),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (sheetContext) {
        return Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: Colors.white10,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              const SizedBox(height: 18),
              const Icon(Icons.lock, color: AstraXTheme.neonBlue, size: 30),
              const SizedBox(height: 12),
              Text(
                message,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.w800,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: () {
                    Navigator.pop(sheetContext);
                    context.go('/profile');
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xFF2563EB),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  child: const Text("Update Profile"),
                ),
              ),
              const SizedBox(height: 8),
              SizedBox(
                width: double.infinity,
                child: TextButton(
                  onPressed: () => Navigator.pop(sheetContext),
                  child: const Text(
                    "Not now",
                    style: TextStyle(color: Colors.white70),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
