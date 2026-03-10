import 'package:flutter/material.dart';

import '../../models/step_explanation.dart';
import 'mistake_explanation_card.dart';
import 'step_explanation_card.dart';
import 'step_explanation_controller.dart';

class StepExplanationList extends StatefulWidget {
  const StepExplanationList({
    super.key,
    required this.steps,
    this.controller,
    this.enableSwipeNavigation = true,
    this.padding = const EdgeInsets.all(16),
    this.onStepChanged,
    this.onCompleted,
    this.mistakeExplanation,
    this.misconception,
  });

  final List<StepExplanation> steps;
  final StepExplanationController? controller;
  final bool enableSwipeNavigation;
  final EdgeInsetsGeometry padding;
  final ValueChanged<int>? onStepChanged;
  final VoidCallback? onCompleted;
  final String? mistakeExplanation;
  final String? misconception;

  @override
  State<StepExplanationList> createState() => _StepExplanationListState();
}

class _StepExplanationListState extends State<StepExplanationList> {
  late StepExplanationController _controller;
  bool _ownsController = false;
  bool _slideFromRight = true;

  @override
  void initState() {
    super.initState();
    _bindController();
  }

  @override
  void didUpdateWidget(covariant StepExplanationList oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      if (_ownsController) {
        _controller.dispose();
      }
      _bindController();
      return;
    }

    if (_ownsController && oldWidget.steps != widget.steps) {
      _controller.setSteps(widget.steps);
    }
  }

  @override
  void dispose() {
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  void _bindController() {
    if (widget.controller != null) {
      _controller = widget.controller!;
      _ownsController = false;
      return;
    }

    _controller = StepExplanationController(steps: widget.steps);
    _ownsController = true;
  }

  void _goNext() {
    if (_controller.canGoNext) {
      setState(() => _slideFromRight = true);
      _controller.nextStep();
      widget.onStepChanged?.call(_controller.currentStepIndex);
      return;
    }
    widget.onCompleted?.call();
  }

  void _goPrevious() {
    if (!_controller.canGoPrevious) return;
    setState(() => _slideFromRight = false);
    _controller.previousStep();
    widget.onStepChanged?.call(_controller.currentStepIndex);
  }

  void _handleDragEnd(DragEndDetails details) {
    if (!widget.enableSwipeNavigation) return;
    final velocity = details.primaryVelocity ?? 0;
    if (velocity < -120) {
      _goNext();
    } else if (velocity > 120) {
      _goPrevious();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (widget.steps.isEmpty) {
      return const Center(child: Text('No step explanations available.'));
    }

    return ListenableBuilder(
      listenable: _controller,
      builder: (context, _) {
        final currentStep = _controller.currentStep;
        if (currentStep == null) {
          return const SizedBox.shrink();
        }

        return Padding(
          padding: widget.padding,
          child: LayoutBuilder(
            builder: (context, constraints) {
              final hasBoundedHeight = constraints.hasBoundedHeight;
              final stepCard = AnimatedSwitcher(
                duration: const Duration(milliseconds: 260),
                switchInCurve: Curves.easeOutCubic,
                switchOutCurve: Curves.easeInCubic,
                transitionBuilder: (child, animation) {
                  final position = Tween<Offset>(
                    begin: Offset(_slideFromRight ? 0.08 : -0.08, 0),
                    end: Offset.zero,
                  ).animate(animation);
                  return FadeTransition(
                    opacity: animation,
                    child: SlideTransition(position: position, child: child),
                  );
                },
                child: StepExplanationCard(
                  key: ValueKey<int>(_controller.currentStepIndex),
                  step: currentStep,
                  stepNumber: _controller.currentStepIndex + 1,
                  totalSteps: _controller.totalSteps,
                  isHintVisible: _controller.isHintVisible(
                    _controller.currentStepIndex,
                  ),
                  onHintToggle: () =>
                      _controller.toggleHint(_controller.currentStepIndex),
                ),
              );

              final stepBody = hasBoundedHeight
                  ? Expanded(
                      child: GestureDetector(
                        onHorizontalDragEnd: _handleDragEnd,
                        child: SingleChildScrollView(
                          child: stepCard,
                        ),
                      ),
                    )
                  : GestureDetector(
                      onHorizontalDragEnd: _handleDragEnd,
                      child: stepCard,
                    );

              return Column(
                mainAxisSize: hasBoundedHeight
                    ? MainAxisSize.max
                    : MainAxisSize.min,
                children: [
                  _buildProgressHeader(context),
                  const SizedBox(height: 12),
                  if (_controller.isMistakeMode &&
                      widget.mistakeExplanation?.trim().isNotEmpty == true) ...[
                    AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      child: MistakeExplanationCard(
                        key: ValueKey<MistakeType>(_controller.mistakeType),
                        explanation: widget.mistakeExplanation!.trim(),
                        misconception: widget.misconception,
                        mistakeType: _controller.mistakeType,
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  stepBody,
                  const SizedBox(height: 14),
                  _buildNavigation(context),
                ],
              );
            },
          ),
        );
      },
    );
  }

  Widget _buildProgressHeader(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final progressPercent = (_controller.progress * 100).round();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Semantics(
          label:
              'Step ${_controller.currentStepIndex + 1} of ${_controller.totalSteps}',
          child: Row(
            children: [
              Expanded(
                child: Text(
                  'Step ${_controller.currentStepIndex + 1} of ${_controller.totalSteps}',
                  style: Theme.of(
                    context,
                  ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                '$progressPercent%',
                style: Theme.of(context).textTheme.labelLarge?.copyWith(
                  color: cs.primary,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        LinearProgressIndicator(
          value: _controller.progress,
          minHeight: 7,
          borderRadius: BorderRadius.circular(99),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 34,
          child: ListView.builder(
            scrollDirection: Axis.horizontal,
            itemCount: _controller.totalSteps,
            itemBuilder: (context, index) {
              final isCurrent = index == _controller.currentStepIndex;
              final isReached = index <= _controller.currentStepIndex;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: Semantics(
                  button: true,
                  label: 'Jump to step ${index + 1}',
                  child: InkWell(
                    borderRadius: BorderRadius.circular(99),
                    onTap: () {
                      setState(() {
                        _slideFromRight = index > _controller.currentStepIndex;
                      });
                      _controller.jumpToStep(index);
                      widget.onStepChanged?.call(index);
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 180),
                      width: 34,
                      height: 34,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: isCurrent
                            ? cs.primary
                            : isReached
                            ? cs.primaryContainer
                            : cs.surfaceContainerHighest,
                      ),
                      child: Text(
                        '${index + 1}',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: isCurrent
                              ? cs.onPrimary
                              : isReached
                              ? cs.onPrimaryContainer
                              : cs.onSurfaceVariant,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  Widget _buildNavigation(BuildContext context) {
    final isLastStep =
        _controller.currentStepIndex == _controller.totalSteps - 1;

    return Row(
      children: [
        Expanded(
          child: OutlinedButton.icon(
            onPressed: _controller.canGoPrevious ? _goPrevious : null,
            icon: const Icon(Icons.arrow_back_ios_new, size: 16),
            label: const Text('Previous'),
            style: OutlinedButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: FilledButton.icon(
            onPressed: _goNext,
            icon: Icon(
              isLastStep ? Icons.check_circle_outline : Icons.arrow_forward,
              size: 18,
            ),
            label: Text(isLastStep ? 'Done' : 'Next Step'),
            style: FilledButton.styleFrom(
              minimumSize: const Size.fromHeight(48),
            ),
          ),
        ),
      ],
    );
  }
}
