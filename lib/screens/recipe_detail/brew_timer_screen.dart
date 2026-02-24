import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../core/theme/app_colors.dart';
import '../../core/theme/app_text_styles.dart';
import '../../models/recipe.dart';
import '../../providers/recipe_provider.dart';

/// Full-screen brew timer that steps through a recipe's steps with a countdown.
class BrewTimerScreen extends ConsumerStatefulWidget {
  const BrewTimerScreen({super.key, required this.recipeId});

  final String recipeId;

  @override
  ConsumerState<BrewTimerScreen> createState() => _BrewTimerScreenState();
}

class _BrewTimerScreenState extends ConsumerState<BrewTimerScreen> {
  int _currentStepIndex = 0;
  int _secondsRemaining = 0;
  int _totalElapsed = 0;
  bool _isRunning = false;
  bool _isComplete = false;
  Timer? _timer;

  List<RecipeStep> _steps = [];

  /// Duration of each step, computed from consecutive start times.
  /// e.g. step 1 starts at 0:00, step 2 at 0:45 → step 1 duration = 45s.
  List<int> _stepDurations = [];

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  void _initSteps(List<RecipeStep> steps, int? brewTimeSec) {
    if (_steps.isEmpty && steps.isNotEmpty) {
      _steps = steps;
      _stepDurations = List.generate(steps.length, (i) {
        if (i < steps.length - 1) {
          return steps[i + 1].stepTimeSec - steps[i].stepTimeSec;
        }
        // Last step: use total brew time if available, otherwise 60s.
        return (brewTimeSec != null)
            ? brewTimeSec - steps[i].stepTimeSec
            : 60;
      });
      _secondsRemaining = _stepDurations[0];
    }
  }

  void _startTimer() {
    if (_isComplete || _steps.isEmpty) return;
    setState(() => _isRunning = true);
    _timer = Timer.periodic(const Duration(seconds: 1), (_) {
      setState(() {
        _totalElapsed++;
        if (_secondsRemaining <= 0) {
          _advanceStep();
        } else {
          _secondsRemaining--;
        }
      });
    });
  }

  void _pauseTimer() {
    _timer?.cancel();
    _timer = null;
    setState(() => _isRunning = false);
  }

  void _advanceStep() {
    if (_currentStepIndex >= _steps.length - 1) {
      _timer?.cancel();
      _timer = null;
      setState(() {
        _isRunning = false;
        _isComplete = true;
      });
      HapticFeedback.heavyImpact();
      return;
    }

    HapticFeedback.mediumImpact();
    setState(() {
      _currentStepIndex++;
      _secondsRemaining = _stepDurations[_currentStepIndex];
    });
  }

  void _skipForward() {
    if (_isComplete) return;
    _advanceStep();
  }

  void _restart() {
    _timer?.cancel();
    _timer = null;
    setState(() {
      _currentStepIndex = 0;
      _secondsRemaining =
          _stepDurations.isNotEmpty ? _stepDurations[0] : 0;
      _totalElapsed = 0;
      _isRunning = false;
      _isComplete = false;
    });
  }

  void _togglePlayPause() {
    if (_isRunning) {
      _pauseTimer();
    } else {
      _startTimer();
    }
  }

  @override
  Widget build(BuildContext context) {
    final recipeAsync = ref.watch(recipeDetailProvider(widget.recipeId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Brew Timer'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: recipeAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Text('Failed to load recipe',
              style: AppTextStyles.bodyLarge
                  .copyWith(color: AppColors.textSecondary)),
        ),
        data: (recipe) {
          final steps = recipe.steps;
          if (steps == null || steps.isEmpty) {
            return Center(
              child: Text('This recipe has no steps.',
                  style: AppTextStyles.bodyLarge
                      .copyWith(color: AppColors.textSecondary)),
            );
          }
          _initSteps(steps, recipe.brewTimeSec);

          if (_isComplete) {
            return _CompletionView(
              totalElapsed: _totalElapsed,
              coffeeId: recipe.coffeeId,
              recipeId: recipe.id,
              onDone: () => context.pop(),
              onRestart: _restart,
            );
          }

          return _TimerBody(
            steps: _steps,
            currentStepIndex: _currentStepIndex,
            secondsRemaining: _secondsRemaining,
            totalElapsed: _totalElapsed,
            isRunning: _isRunning,
            onTogglePlayPause: _togglePlayPause,
            onSkipForward: _skipForward,
            onRestart: _restart,
          );
        },
      ),
    );
  }
}

// ── Timer Body ───────────────────────────────────────────────────────────────

class _TimerBody extends StatelessWidget {
  const _TimerBody({
    required this.steps,
    required this.currentStepIndex,
    required this.secondsRemaining,
    required this.totalElapsed,
    required this.isRunning,
    required this.onTogglePlayPause,
    required this.onSkipForward,
    required this.onRestart,
  });

  final List<RecipeStep> steps;
  final int currentStepIndex;
  final int secondsRemaining;
  final int totalElapsed;
  final bool isRunning;
  final VoidCallback onTogglePlayPause;
  final VoidCallback onSkipForward;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    final step = steps[currentStepIndex];
    final hasNext = currentStepIndex < steps.length - 1;

    return SafeArea(
      child: LayoutBuilder(
        builder: (context, constraints) => SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: ConstrainedBox(
            constraints: BoxConstraints(minHeight: constraints.maxHeight),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                // ── Top: progress ──
                Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: _ProgressHeader(
                    currentStep: currentStepIndex,
                    totalSteps: steps.length,
                  ),
                ),

                // ── Center: step info + countdown ──
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Column(
                    children: [
                      Text(
                        step.description,
                        style: AppTextStyles.titleLarge,
                        textAlign: TextAlign.center,
                      ),
                      if (step.waterMl != null) ...[
                        const SizedBox(height: 8),
                        Text(
                          '${step.waterMl!.toStringAsFixed(0)}ml',
                          style: AppTextStyles.titleMedium.copyWith(
                            color: AppColors.primary,
                          ),
                        ),
                      ],
                      const SizedBox(height: 32),
                      Text(
                        formatStepTime(secondsRemaining),
                        style: AppTextStyles.displayLarge.copyWith(
                          fontFeatures: [const FontFeature.tabularFigures()],
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Total: ${formatStepTime(totalElapsed)}',
                        style: AppTextStyles.bodyMedium.copyWith(
                          color: AppColors.textSecondary,
                        ),
                      ),
                    ],
                  ),
                ),

                // ── Bottom: next preview + controls ──
                Column(
                  children: [
                    if (hasNext) ...[
                      _NextStepPreview(step: steps[currentStepIndex + 1]),
                      const SizedBox(height: 24),
                    ],
                    _ControlsRow(
                      isRunning: isRunning,
                      onTogglePlayPause: onTogglePlayPause,
                      onSkipForward: onSkipForward,
                      onRestart: onRestart,
                    ),
                    const SizedBox(height: 24),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Progress Header ──────────────────────────────────────────────────────────

class _ProgressHeader extends StatelessWidget {
  const _ProgressHeader({
    required this.currentStep,
    required this.totalSteps,
  });

  final int currentStep;
  final int totalSteps;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: LinearProgressIndicator(
            value: (currentStep + 1) / totalSteps,
            backgroundColor: AppColors.surface,
            valueColor:
                const AlwaysStoppedAnimation<Color>(AppColors.primary),
            minHeight: 6,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Step ${currentStep + 1} of $totalSteps',
          style: AppTextStyles.labelMedium.copyWith(
            color: AppColors.textSecondary,
          ),
        ),
      ],
    );
  }
}

// ── Next Step Preview ────────────────────────────────────────────────────────

class _NextStepPreview extends StatelessWidget {
  const _NextStepPreview({required this.step});

  final RecipeStep step;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'NEXT',
            style: AppTextStyles.kicker.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
          const SizedBox(height: 6),
          Text(step.description, style: AppTextStyles.bodyMedium),
          const SizedBox(height: 4),
          Text(
            formatStepTime(step.stepTimeSec),
            style: AppTextStyles.bodySmall.copyWith(
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }
}

// ── Controls Row ─────────────────────────────────────────────────────────────

class _ControlsRow extends StatelessWidget {
  const _ControlsRow({
    required this.isRunning,
    required this.onTogglePlayPause,
    required this.onSkipForward,
    required this.onRestart,
  });

  final bool isRunning;
  final VoidCallback onTogglePlayPause;
  final VoidCallback onSkipForward;
  final VoidCallback onRestart;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        // Restart
        IconButton(
          onPressed: onRestart,
          icon: const Icon(Icons.restart_alt_rounded),
          iconSize: 32,
          color: AppColors.textSecondary,
        ),

        const SizedBox(width: 24),

        // Play / Pause
        Container(
          width: 72,
          height: 72,
          decoration: BoxDecoration(
            gradient: AppColors.accentGradient,
            shape: BoxShape.circle,
            boxShadow: AppColors.primaryGlow,
          ),
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              onTap: onTogglePlayPause,
              customBorder: const CircleBorder(),
              child: Icon(
                isRunning
                    ? Icons.pause_rounded
                    : Icons.play_arrow_rounded,
                size: 36,
                color: AppColors.white,
              ),
            ),
          ),
        ),

        const SizedBox(width: 24),

        // Skip forward
        IconButton(
          onPressed: onSkipForward,
          icon: const Icon(Icons.skip_next_rounded),
          iconSize: 32,
          color: AppColors.textSecondary,
        ),
      ],
    );
  }
}

// ── Completion View ──────────────────────────────────────────────────────────

class _CompletionView extends StatelessWidget {
  const _CompletionView({
    required this.totalElapsed,
    required this.onDone,
    required this.onRestart,
    this.coffeeId,
    this.recipeId,
  });

  final int totalElapsed;
  final VoidCallback onDone;
  final VoidCallback onRestart;
  final String? coffeeId;
  final String? recipeId;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: AppColors.primaryLight.withValues(alpha: 0.2),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.check_rounded,
                  size: 48,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(height: 24),
              Text('Brew Complete!', style: AppTextStyles.headlineMedium),
              const SizedBox(height: 12),
              Text(
                'Total time: ${formatStepTime(totalElapsed)}',
                style: AppTextStyles.titleMedium.copyWith(
                  color: AppColors.textSecondary,
                ),
              ),
              const SizedBox(height: 40),
              SizedBox(
                width: 200,
                child: ElevatedButton(
                  onPressed: () {
                    final params = <String>[];
                    if (coffeeId != null) params.add('coffeeId=$coffeeId');
                    if (recipeId != null) params.add('recipeId=$recipeId');
                    final query =
                        params.isNotEmpty ? '?${params.join('&')}' : '';
                    context.go('/check-in$query');
                  },
                  child: const Text('Log Check-in'),
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                width: 200,
                child: OutlinedButton(
                  onPressed: onDone,
                  child: const Text('Done'),
                ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: onRestart,
                child: const Text('Restart'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
