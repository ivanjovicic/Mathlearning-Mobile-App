import 'package:flutter/material.dart';

class PracticeBottomCta extends StatelessWidget {
  const PracticeBottomCta({
    super.key,
    required this.enabled,
    required this.busy,
    required this.isLastQuestion,
    required this.onPressed,
    this.useGateCopy = false,
  });

  final bool enabled;
  final bool busy;
  final bool isLastQuestion;
  final VoidCallback onPressed;
  final bool useGateCopy;

  @override
  Widget build(BuildContext context) {
    final label = useGateCopy
        ? 'Clear Gate'
        : isLastQuestion
        ? 'Done! →'
        : 'Next →';
    return SizedBox(
      width: double.infinity,
      child: FilledButton.icon(
        onPressed: enabled && !busy ? onPressed : null,
        icon: busy
            ? const SizedBox(
                width: 18,
                height: 18,
                child: CircularProgressIndicator(strokeWidth: 2),
              )
            : Icon(
                isLastQuestion
                    ? Icons.flag_rounded
                    : Icons.arrow_forward_rounded,
              ),
        label: Text(label),
      ),
    );
  }
}
