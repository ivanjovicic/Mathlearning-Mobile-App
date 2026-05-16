# Quiz Flow Refactor Notes

## Current Problem
`QuizProvider.answer()` currently owns submit, progress update, SnackBar, completion navigation, and summary construction.

## Target
`QuizProvider.answer()` should return a `QuizAnswerResult` and not require `BuildContext`. Screens should own SnackBars and navigation.

## Proposed Result Model
- `isCorrect`
- `submitStatus`
- `queuedOffline`
- `failedToPersist`
- `completedQuiz`
- `summaryStats` nullable
- `awardedXp`

## Migration Plan
1. Introduce `answerWithoutContext` or `answerResult`.
2. Keep the old `answer()` wrapper temporarily.
3. Update `QuizScreen`.
4. Update `GamifiedQuizScreen`.
5. Update the Daily Review screen if applicable.
6. Delete the old wrapper once callers are migrated.

## Affected Files
- `lib/state/quiz_provider.dart`
- `lib/screens/quiz_screen.dart`
- `lib/screens/home/gamified_quiz_screen.dart`
- daily review screen if it calls `QuizProvider.answer()`

## Notes
- Preserve result navigation, offline SnackBar behavior, and LevelUp/Achievement popup behavior during migration.
