# Quiz Flow Refactor Notes

## Current Issue
`QuizProvider.answer()` currently owns submit, progress update, offline SnackBar, completion navigation, level-up dialog, achievement popup, and results navigation.

## Target
`QuizProvider.answer()` returns `QuizAnswerResult` and does not require `BuildContext`.
Screens own SnackBars, dialogs, and navigation.

## Proposed Result Model
- `isCorrect`
- `submitStatus`
- `queuedOffline`
- `failedToPersist`
- `completedQuiz`
- `summaryStats` nullable
- `awardedXp`
- `levelUp` nullable
- `achievement` nullable

## Migration Steps
1. Introduce `answerResult` method.
2. Keep old `answer` wrapper temporarily.
3. Update `QuizScreen`.
4. Update `GamifiedQuizScreen`.
5. Update DailyReview screen if applicable.
6. Delete old wrapper.
