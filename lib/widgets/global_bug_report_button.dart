import 'package:flutter/material.dart';

import '../services/bug_capture_service.dart';
import '../services/bug_report_service.dart';
import '../services/route_tracker.dart';
import '../utils/overlay_safety.dart';

enum _ReportMode { bug, uxUiFeedback }

class GlobalBugReportButton extends StatefulWidget {
  const GlobalBugReportButton({super.key});

  @override
  State<GlobalBugReportButton> createState() => _GlobalBugReportButtonState();
}

class _GlobalBugReportButtonState extends State<GlobalBugReportButton> {
  Future<void> _openReportSheet(BuildContext context) async {
    final route = RouteTracker.instance.currentRoute.value;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) {
        return _ReportSheet(initialScreen: route);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.only(right: 16, bottom: 16),
        child: FloatingActionButton.small(
          heroTag: null,
          tooltip: context.safeTooltip('Prijavi bag ili UX/UI utisak'),
          onPressed: () => _openReportSheet(context),
          child: const Icon(Icons.feedback_outlined),
        ),
      ),
    );
  }
}

class _ReportSheet extends StatefulWidget {
  const _ReportSheet({required this.initialScreen});

  final String initialScreen;

  @override
  State<_ReportSheet> createState() => _ReportSheetState();
}

class _ReportSheetState extends State<_ReportSheet> {
  final TextEditingController _descriptionController = TextEditingController();
  final TextEditingController _stepsController = TextEditingController();
  final TextEditingController _suggestionController = TextEditingController();

  bool _submitting = false;
  _ReportMode _mode = _ReportMode.bug;
  String _severity = 'medium';
  double _uxRating = 3;
  bool _liked = true;

  @override
  void dispose() {
    _descriptionController.dispose();
    _stepsController.dispose();
    _suggestionController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    final description = _descriptionController.text.trim();
    if (description.length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unesi detaljniji opis.')),
      );
      return;
    }

    if (_mode == _ReportMode.bug && _stepsController.text.trim().length < 5) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Unesi korake za reprodukciju baga.')),
      );
      return;
    }

    setState(() => _submitting = true);
    final screenshotBase64 =
        await BugCaptureService.instance.captureScreenshotBase64();

    late final BugReportSubmitResult result;
    if (_mode == _ReportMode.bug) {
      result = await BugReportService.instance.submitReport(
        screen: widget.initialScreen,
        description: description,
        severity: _severity,
        stepsToReproduce: _stepsController.text.trim(),
        screenshotBase64: screenshotBase64,
      );
    } else {
      result = await BugReportService.instance.submitUxUiFeedback(
        screen: widget.initialScreen,
        description: description,
        uxRating: _uxRating.round(),
        liked: _liked,
        suggestion: _suggestionController.text.trim().isEmpty
            ? null
            : _suggestionController.text.trim(),
        screenshotBase64: screenshotBase64,
      );
    }

    if (!mounted) return;
    setState(() => _submitting = false);
    Navigator.of(context).pop();

    final message = result == BugReportSubmitResult.sent
        ? 'Prijava poslata.'
        : 'Nema mreze. Prijava je sacuvana i bice poslata kasnije.';
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    final insets = MediaQuery.of(context).viewInsets;

    return Padding(
      padding: EdgeInsets.fromLTRB(16, 16, 16, 16 + insets.bottom),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Prijava',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          Text(
            'Ekran: ${widget.initialScreen}',
            style: const TextStyle(fontSize: 13, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          DropdownButtonFormField<_ReportMode>(
            initialValue: _mode,
            decoration: const InputDecoration(
              labelText: 'Tip prijave',
              border: OutlineInputBorder(),
            ),
            items: const [
              DropdownMenuItem(
                value: _ReportMode.bug,
                child: Text('Bug'),
              ),
              DropdownMenuItem(
                value: _ReportMode.uxUiFeedback,
                child: Text('UX/UI feedback'),
              ),
            ],
            onChanged: _submitting
                ? null
                : (value) {
                    if (value == null) return;
                    setState(() => _mode = value);
                  },
          ),
          const SizedBox(height: 12),
          if (_mode == _ReportMode.bug) ...[
            DropdownButtonFormField<String>(
              initialValue: _severity,
              decoration: const InputDecoration(
                labelText: 'Severity',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(value: 'low', child: Text('Low')),
                DropdownMenuItem(value: 'medium', child: Text('Medium')),
                DropdownMenuItem(value: 'high', child: Text('High')),
                DropdownMenuItem(value: 'critical', child: Text('Critical')),
              ],
              onChanged: _submitting
                  ? null
                  : (value) {
                      if (value == null) return;
                      setState(() => _severity = value);
                    },
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _stepsController,
              maxLines: 4,
              minLines: 2,
              decoration: const InputDecoration(
                hintText: 'Koraci za reprodukciju baga',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
          ],
          if (_mode == _ReportMode.uxUiFeedback) ...[
            SwitchListTile.adaptive(
              contentPadding: EdgeInsets.zero,
              title: const Text('Svidja mi se UX/UI'),
              value: _liked,
              onChanged: _submitting ? null : (v) => setState(() => _liked = v),
            ),
            const SizedBox(height: 4),
            Text('Ocena UX/UI: ${_uxRating.round()} / 5'),
            Slider(
              value: _uxRating,
              min: 1,
              max: 5,
              divisions: 4,
              label: _uxRating.round().toString(),
              onChanged:
                  _submitting ? null : (v) => setState(() => _uxRating = v),
            ),
            TextField(
              controller: _suggestionController,
              maxLines: 3,
              minLines: 2,
              decoration: const InputDecoration(
                hintText: 'Predlog poboljsanja (opciono)',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
          ],
          TextField(
            controller: _descriptionController,
            maxLines: 5,
            minLines: 3,
            decoration: InputDecoration(
              hintText: _mode == _ReportMode.bug
                  ? 'Opisi sta se desilo.'
                  : 'Opisi utisak o UX/UI (sta je dobro / lose).',
              border: const OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _submitting ? null : _submit,
              child: _submitting
                  ? const SizedBox(
                      width: 18,
                      height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Posalji'),
            ),
          ),
        ],
      ),
    );
  }
}
