# Quiz Flow Refactor Notes

## Goal
Decouple `QuizProvider.answer()` from `BuildContext` so the provider only updates state and returns a structured result, while UI code owns SnackBars, dialogs, and navigation.

## Target Shape
`QuizProvider.answer()` should return a `QuizAnswerResult` that describes:
- whether the answer was correct
- whether the quiz was completed
- whether the answer was queued offline, confirmed by server, or failed to persist
- any data needed by the UI for the next action

## Migration Plan
1. Introduce `QuizAnswerResult` in `quiz_provider.dart`.
2. Update `QuizProvider.answer()` to stop calling UI APIs directly.
3. Move SnackBar handling, dialogs, and result navigation into the screen layer.
4. Keep the current runtime behavior during migration by preserving the same visible user flows.
5. Update callers to react to the returned result instead of inferring side effects from provider internals.

## Affected Files
- `lib/state/quiz_provider.dart`
- `lib/screens/quiz_screen.dart`
- `lib/screens/home/gamified_quiz_screen.dart`
- `lib/screens/daily_review_screen.dart` if it uses `QuizProvider.answer()` directly

## Notes
- This refactor should be incremental.
- No business logic changes should happen during the first pass.
- The UI should remain responsible for user-facing feedback and navigation decisions.
