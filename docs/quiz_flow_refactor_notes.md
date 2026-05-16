# Quiz Flow Refactor Notes

## Current Problem
`QuizProvider.answer()` currently owns submit, progress updates, SnackBar feedback, completion navigation, and dialogs.

## Target
`QuizProvider.answer()` should return a `QuizAnswerResult`, and the UI should own SnackBars, dialogs, and navigation.

## Migration Plan
1. Introduce `QuizAnswerResult` in `quiz_provider.dart`.
2. Keep the old `answer()` path temporarily during migration.
3. Move completion navigation into the screen layer.
4. Remove `BuildContext` from the provider once callers are updated.
5. Preserve current runtime behavior while the UI takes over the side effects.

## Affected Files
- `lib/state/quiz_provider.dart`
- `lib/screens/quiz_screen.dart`
- `lib/screens/home/gamified_quiz_screen.dart`
- daily review screen if it calls `QuizProvider.answer()`

## Notes
- This refactor should stay incremental.
- No business logic changes should happen in the first pass.
