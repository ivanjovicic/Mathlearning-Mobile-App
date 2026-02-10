import 'package:flutter/material.dart';
import '../theme/astrax_theme.dart';

class AstraToggle extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const AstraToggle({
    super.key,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        width: 60,
        height: 32,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(30),
          color: value ? AstraXTheme.neonPurple.withValues(alpha: 0.35) : Colors.white10,
          border: Border.all(
            color: value ? AstraXTheme.neonPurple.withValues(alpha: 0.7) : Colors.white24,
            width: 1.3,
          ),
        ),
        child: AnimatedAlign(
          duration: const Duration(milliseconds: 160),
          curve: Curves.easeOut,
          alignment: value ? Alignment.centerRight : Alignment.centerLeft,
          child: Container(
            margin: const EdgeInsets.all(4),
            width: 22,
            height: 22,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: value ? AstraXTheme.neonPurple : Colors.white30,
              boxShadow: [
                if (value)
                  BoxShadow(
                    color: AstraXTheme.neonPurple.withValues(alpha: 0.7),
                    blurRadius: 14,
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
