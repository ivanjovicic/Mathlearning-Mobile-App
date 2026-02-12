import 'package:flutter/material.dart';

import 'global_bug_report_button.dart';

class ScreenWrapper extends StatelessWidget {
  final Widget child;
  final bool showBugReportButton;

  const ScreenWrapper({
    super.key,
    required this.child,
    this.showBugReportButton = true,
  });

  @override
  Widget build(BuildContext context) {
    if (!showBugReportButton) {
      return child;
    }

    return Stack(
      children: [
        child,
        const Align(
          alignment: Alignment.bottomRight,
          child: GlobalBugReportButton(),
        ),
      ],
    );
  }
}
