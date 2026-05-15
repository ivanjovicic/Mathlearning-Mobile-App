# MathLearning Backend API Specification
**Flutter Mobile Client Compatibility**

Generated: May 15, 2026  
Status: Updated for backend contract compatibility

---

## Overview

This document lists all backend API endpoints currently used by the Flutter mobile client. Each endpoint is grouped by feature and includes HTTP method, path, query/body parameters, and backend compatibility status.

## Final Flutter Runtime Notes (May 15, 2026)

- `GET /api/analytics/mastery` is unsupported and is not called by Flutter runtime code.
- `/api/chase/*` is unsupported and is not called by Flutter runtime code.
- School history requests use only `period` + `take`; Flutter does not rely on `from`/`to` date filtering.
- Backend compatibility aliases exist, but Flutter should prefer canonical routes:
  - `/api/user/profile/{userId}` over `/api/users/{userId}/profile`
  - `/api/adaptive/reviews/due` over `/api/adaptive/review`
- `/api/leaderboard/rivals` exists as a backend compatibility alias and returns the friends-style leaderboard shape.

---

## Auth

### POST /api/auth/login
- **Purpose:** Authenticate user with email and password
- **Body:** `email`, `password`
- **Response:** `AuthToken` with JWT token and user profile
- **Flutter Call:** `AuthApi.loginMobileUser()` in `api_service.dart` and `AuthRepository.login()` in `auth_repository.dart`
- **Status:** ✅ Confirmed

### POST /auth/mobile/register
- **Purpose:** Register a new mobile user
- **Body:** `username`, `email`, `password`, `displayName`
- **Response:** User profile data
- **Flutter Call:** `AuthApi.registerMobileUser()` in `api_service.dart`
- **Status:** ✅ Confirmed

---

## Users

### GET /api/users/profile
- **Purpose:** Get current authenticated user's profile
- **Auth:** Required
- **Response:** User profile data
- **Flutter Call:** `UserApi.getUserProfile()` in `api_service.dart`
- **Status:** ✅ Confirmed

### GET /api/user/profile/{userId}
- **Purpose:** Get another user's profile by ID
- **Auth:** Required
- **Path Param:** `userId` (string)
- **Response:** User profile data
- **Flutter Call:** `UserApi.getUserProfileById(userId)` in `api_service.dart`
- **Status:** ✅ Confirmed (Replaced `/api/users/{userId}/profile`)
- **Notes:** Endpoint path corrected in this release

### PUT /api/users/profile
- **Purpose:** Update current user's profile
- **Auth:** Required
- **Body:** `displayName?`, `email?` (optional fields)
- **Response:** Updated user profile data
- **Flutter Call:** `UserApi.updateUserProfile()` in `api_service.dart`
- **Status:** ✅ Confirmed

### GET /api/users/search
- **Purpose:** Search for users by query string
- **Auth:** Required
- **Query Params:** `query` (search string)
- **Response:** List of user profiles
- **Flutter Call:** `ApiService.searchUsers(query)` in `api_service.dart`
- **Status:** ✅ Confirmed

### GET /api/user/coins
- **Purpose:** Get current user's coin balance
- **Auth:** Required
- **Response:** Integer coin count
- **Flutter Call:** `ApiService.getUserCoins()` in `api_service.dart`
- **Status:** ✅ Confirmed

---

## Quiz / Practice Sessions

### POST /api/quiz/start
- **Purpose:** Start a quiz session
- **Auth:** Required
- **Body:** `subtopicId`, `questionCount`
- **Response:** Quiz session data with questions
- **Flutter Call:** `QuizApi.startQuiz()` in `api_service.dart`
- **Status:** ✅ Confirmed

### POST /api/quiz/answer
- **Purpose:** Submit an answer for a quiz question
- **Auth:** Required
- **Body:** `quizId`, `questionId`, `answer`, `timeSpentSeconds`
- **Response:** Answer evaluation and next question (if any)
- **Flutter Call:** `QuizApi.submitAnswer()` in `api_service.dart`
- **Status:** ✅ Confirmed

### GET /api/quiz/questions
- **Purpose:** Get quiz questions (topic/subtopic specific)
- **Auth:** Required
- **Query Params:** topic/subtopic IDs (inferred)
- **Response:** List of questions
- **Flutter Call:** `ApiService.getQuizQuestions()` in `api_service.dart`
- **Status:** ✅ Confirmed

---

## Progress

### GET /api/progress/overview
- **Purpose:** Get user's overall progress summary
- **Auth:** Required
- **Response:** `ProgressOverview` object (totalQuizzes, completedQuizzes, averageScore, bestScore, lastQuizDate)
- **Flutter Call:** `ProgressApi.getProgressOverview()` in `api_service.dart`
- **Status:** ✅ Confirmed

### GET /api/progress/topics
- **Purpose:** Get progress for each topic/subtopic
- **Auth:** Required
- **Response:** List of topic progress items
- **Flutter Call:** `ApiService.getTopicsProgress()` in `api_service.dart`
- **Status:** ✅ Confirmed

---

## Adaptive Learning

- **Canonical practice flow:** The mobile client should prefer the practice-session endpoints under
  `/api/practice/session/*` for the adaptive practice UI. These endpoints are exposed via
  `PracticeSessionApiService` in the Flutter codebase and are the canonical implementation for
  practice rounds (start, answer, complete).

- **Legacy endpoints:** The `/api/adaptive/*` endpoints (for example `/api/adaptive/session/start`,
  `/api/adaptive/session/answer`, `/api/adaptive/reviews/due`, `/api/adaptive/path`) are legacy
  for practice flows. They remain accessible via `ApiService` for compatibility but are marked as
  deprecated for practice UI and scheduled for consolidation. Prefer `/api/practice/session/*`.


### POST /api/adaptive/session/start
- **Purpose:** Start an adaptive learning session
- **Auth:** Required
- **Body:** Empty object `{}`
- **Notes:** `topicId` and `topic` parameters are accepted by client but NOT sent to backend (not yet supported)
- **Response:** Session object with `sessionId`, `questions`, `topic`, `difficulty`
- **Flutter Call:** `ApiService.startAdaptiveSessionResult()` in `api_service.dart`
- **Status:** ⚠️ Partial - Topic targeting not yet supported by backend
- **TODO:** Implement topic-targeted adaptive sessions when backend supports `topicId`/`topic` in request

### POST /api/adaptive/session/answer
- **Purpose:** Submit an answer in an adaptive session
- **Auth:** Required
- **Body:** 
  - `adaptiveSessionId` (string) — session ID (uses `sessionId` as fallback if not provided)
  - `adaptiveSessionItemId` (string, optional) — specific session item ID
  - `questionId` (integer)
  - `answer` (string)
  - `responseTimeMs` (integer, optional)
- **Response:** Answer evaluation and next question
- **Flutter Call:** `ApiService.submitAdaptiveSessionAnswerResult()` in `api_service.dart`
- **Status:** ⚠️ Partial - Updated to match backend requirements
- **Notes:** Method signature updated; callers passing only `sessionId` will use it as `adaptiveSessionId` fallback
- **TODO:** Provide `adaptiveSessionItemId` from adaptive session item when available

### GET /api/adaptive/path
- **Purpose:** Get the full adaptive learning path for the user
- **Auth:** Required
- **Response:** `AdaptiveLearningPath` object with skill nodes, progress, mastery
- **Flutter Call:** `ApiService.getAdaptivePathForUserResult()` in `api_service.dart`
- **Status:** ✅ Confirmed

### GET /api/adaptive/recommendations
- **Purpose:** Get adaptive learning recommendations for next practice
- **Auth:** Required
- **Response:** Recommendation object (topic, difficulty, questionCount, etc.)
- **Flutter Call:** `ApiService.getAdaptiveRecommendationsResult()` in `api_service.dart`
- **Status:** ✅ Confirmed

### GET /api/adaptive/reviews/due
- **Purpose:** Get adaptive review items due for the user
- **Auth:** Required
- **Response:** List of review items (plain list, or wrapped in `items`/`data` key)
- **Flutter Call:** `ApiService.getAdaptiveReviewResult()` in `api_service.dart`
- **Status:** ✅ Confirmed (Replaced `/api/adaptive/review`)
- **Notes:** Endpoint path updated in this release; response normalization expanded to support `data` wrapper

---

## Analytics / Recommendations

### GET /api/analytics/weakness
- **Purpose:** Get user's weak areas (low-accuracy topics)
- **Auth:** Required
- **Query Params:** `page` (default 1), `pageSize` (default 5)
- **Response:** List of weak topic entries
- **Flutter Call:** `ApiService.getWeaknessForUserResult()` in `api_service.dart`
- **Status:** ✅ Confirmed

### GET /api/analytics/weakness/details
- **Purpose:** Get detailed analytics for weak areas
- **Auth:** Required
- **Query Params:** `page`, `pageSize`
- **Response:** Detailed weakness data
- **Flutter Call:** Extended weakness endpoint (if used)
- **Status:** ⚠️ Not actively called by current client

### GET /api/analytics/mastery
- **Purpose:** Get user's areas of mastery (high-accuracy topics)
- **Auth:** Required
- **Query Params:** `page`, `pageSize`
- **Response:** (Endpoint not available)
- **Flutter Call:** `ApiService.getMasteryForUserResult()` in `api_service.dart`
- **Status:** ❌ NOT AVAILABLE - Backend does not provide this endpoint
- **Fallback:** Returns empty list with TODO comment
- **Alternative:** Use `/api/adaptive/path` for mastery-like progress data

### GET /api/recommendations/practice
- **Purpose:** Get personalized practice recommendations
- **Auth:** Required
- **Query Params:** `page` (default 1), `pageSize` (default 10)
- **Response:** List of practice recommendation objects
- **Flutter Call:** `ApiService.getPracticeRecommendationsForUserResult()` in `api_service.dart`
- **Status:** ✅ Confirmed

---

## Leaderboard

### GET /api/leaderboard
- **Purpose:** Get global leaderboard (all users)
- **Auth:** Required
- **Query Params:** `period` (time period), pagination params
- **Response:** Leaderboard items with user scores and cosmetics
- **Flutter Call:** `ApiService.getLeaderboard()` in `api_service.dart`
- **Status:** ✅ Confirmed

### GET /api/leaderboard/friends
- **Purpose:** Get friends/rivals leaderboard
- **Auth:** Required
- **Query Params:** `period`
- **Response:** List of rival/friend leaderboard entries
- **Flutter Call:** `ApiService.fetchLeaderboardRivals()` in `api_service.dart`
- **Status:** ✅ Confirmed (Replaced `/api/leaderboard/rivals`)
- **Notes:** Endpoint path corrected in this release

### GET /api/leaderboard/student
- **Purpose:** Get school-based leaderboard (students in your school)
- **Auth:** Required
- **Query Params:** `period`
- **Response:** School leaderboard items
- **Flutter Call:** `ApiService.getSchoolLeaderboard()` in `api_service.dart`
- **Status:** ✅ Confirmed

### GET /api/leaderboard/schools
- **Purpose:** Get list of all schools
- **Auth:** Required
- **Response:** List of school objects with rankings
- **Flutter Call:** `ApiService.getSchools()` in `api_service.dart`
- **Status:** ✅ Confirmed

### GET /api/leaderboard/schools/{schoolId}
- **Purpose:** Get leaderboard for a specific school
- **Auth:** Required
- **Path Param:** `schoolId` (integer)
- **Query Params:** `period`
- **Response:** School leaderboard detail
- **Flutter Call:** `ApiService.fetchSchoolLeaderboard()` in `api_service.dart`
- **Status:** ✅ Confirmed

### GET /api/leaderboard/schools/history/{schoolId}
- **Purpose:** Get historical ranking data for a school
- **Auth:** Required
- **Path Param:** `schoolId` (integer)
- **Query Params:** `period`, `take` (number of history entries, default 30)
- **Response:** List of historical leaderboard snapshots
- **Flutter Call:** `ApiService.fetchSchoolLeaderboardHistory()` in `api_service.dart`
- **Status:** ✅ Confirmed (Updated parameters)
- **Notes:** 
  - Endpoint now uses `take` instead of `from`/`to` date range
  - Legacy `from`/`to` parameters deprecated and ignored
  - `take` parameter added (default 30)

### GET /api/leaderboard/rivals
- **Purpose:** (Replaced by `/api/leaderboard/friends`)
- **Status:** ❌ DEPRECATED - Use `/api/leaderboard/friends` instead

---

## Hints

### GET /api/hints/daily
- **Purpose:** Get daily hint (special hint of the day)
- **Auth:** Required
- **Response:** Hint object with content, category, etc.
- **Flutter Call:** `ApiService.getDailyHint()` in `api_service.dart`
- **Status:** ✅ Confirmed

### GET /api/hints/formula
- **Purpose:** Get formula hint for a topic
- **Auth:** Required
- **Query Params:** `topicId`, `questionId`
- **Response:** Formula hint text
- **Flutter Call:** `ApiService.getFormulaHint()` in `api_service.dart`
- **Status:** ✅ Confirmed

### GET /api/hints/clue
- **Purpose:** Get clue hint (small hint about the problem)
- **Auth:** Required
- **Query Params:** `questionId`
- **Response:** Clue hint text
- **Flutter Call:** `ApiService.getClueHint()` in `api_service.dart`
- **Status:** ✅ Confirmed

### GET /api/hints/eliminate
- **Purpose:** Get elimination hint (eliminate wrong answers)
- **Auth:** Required
- **Query Params:** `questionId`
- **Response:** List of eliminated answers or indices
- **Flutter Call:** `ApiService.getEliminateHint()` in `api_service.dart`
- **Status:** ✅ Confirmed

---

## Practice Sessions

### POST /api/practice/session/start
- **Purpose:** Start a practice session (different from quiz)
- **Auth:** Required
- **Body:** `topicId`, `questionCount`, `difficulty` (optional)
- **Response:** Practice session with questions
- **Flutter Call:** `ApiService.startPracticeSession()` in `api_service.dart`
- **Status:** ✅ Confirmed

### POST /api/practice/session/{sessionId}/answer
- **Purpose:** Submit an answer in a practice session
- **Auth:** Required
- **Path Param:** `sessionId` (string)
- **Body:** `questionId`, `answer`, `timeSpentSeconds` (optional)
- **Response:** Answer evaluation and next question
- **Flutter Call:** `ApiService.submitPracticeAnswer()` in `api_service.dart`
- **Status:** ✅ Confirmed

### POST /api/practice/session/{sessionId}/complete
- **Purpose:** Mark practice session as complete
- **Auth:** Required
- **Path Param:** `sessionId` (string)
- **Response:** Session completion summary
- **Flutter Call:** `ApiService.completePracticeSession()` in `api_service.dart`
- **Status:** ✅ Confirmed

---

## Spaced Repetition System (SRS)

### GET /api/quiz/srs/daily
- **Purpose:** Get daily SRS review questions
- **Auth:** Required
- **Query Params:** `limit` (optional, default varies)
- **Response:** List of SRS review questions
- **Flutter Call:** `SrsService.getSrsDaily()` in `srs_service.dart`
- **Status:** ✅ Confirmed

### GET /api/quiz/srs/mixed
- **Purpose:** Get mixed SRS review (blend of due reviews and new items)
- **Auth:** Required
- **Query Params:** `limit` (optional)
- **Response:** List of mixed SRS items
- **Flutter Call:** `SrsService.getSrsMixed()` in `srs_service.dart`
- **Status:** ✅ Confirmed

### GET /api/quiz/srs/streak
- **Purpose:** Get user's SRS streak data
- **Auth:** Required
- **Response:** Streak object with count, current streak, best streak
- **Flutter Call:** `SrsService.getSrsStreak()` in `srs_service.dart`
- **Status:** ✅ Confirmed

### POST /api/quiz/srs/update
- **Purpose:** Update SRS item intervals and review state
- **Auth:** Required
- **Body:** `itemId`, `grade` (1-5), `elapsedDays` (optional)
- **Response:** Updated SRS item state
- **Flutter Call:** `SrsService.updateSrsItem()` in `srs_service.dart`
- **Status:** ✅ Confirmed

---

## Seasons

### GET /api/seasons/active
- **Purpose:** Get current active season info
- **Auth:** Required
- **Response:** Season object with theme, rewards, duration, etc.
- **Flutter Call:** `SeasonService.getActiveSeason()` in `season_service.dart`
- **Status:** ✅ Confirmed

---

## Progress Sync

### POST /api/progress/sync
- **Purpose:** Push local progress data to server
- **Auth:** Required
- **Body:** Progress object with quiz results, timestamps, etc.
- **Response:** Sync confirmation and server state
- **Flutter Call:** `ProgressService.syncProgress()` in `progress_service.dart`
- **Status:** ✅ Confirmed

### GET /api/progress/week-activity
- **Purpose:** Get user's activity heatmap data (week-wise)
- **Auth:** Required
- **Query Params:** `startDate` (optional), `endDate` (optional)
- **Response:** Activity heatmap data
- **Flutter Call:** `HeatmapProvider` in `heatmap_provider.dart`
- **Status:** ✅ Confirmed

---

## Cosmetics

### GET /api/cosmetics/avatar
- **Purpose:** Get available cosmetic items (avatars, frames, etc.)
- **Auth:** Optional
- **Response:** List of cosmetic items with rarity, unlock conditions, etc.
- **Flutter Call:** `CosmeticsService.getCatalog()` in `cosmetics_service.dart`
- **Status:** ✅ Confirmed

### GET /api/cosmetics/inventory
- **Purpose:** Get user's cosmetic inventory (owned items)
- **Auth:** Required
- **Response:** User's cosmetic item inventory
- **Flutter Call:** `CosmeticsService.getInventory()` in `cosmetics_service.dart`
- **Status:** ✅ Confirmed

### POST /api/cosmetics/purchase
- **Purpose:** Purchase a cosmetic item
- **Auth:** Required
- **Body:** `itemId`, cost/currency info
- **Response:** Updated inventory
- **Flutter Call:** (Inferred from cosmetics logic)
- **Status:** ⚠️ Not directly exposed in current client

---

## Chase Race / Target Cosmetics

### GET /api/chase-race/{itemId}
- **Purpose:** Get chase race data for a target cosmetic item
- **Auth:** Required
- **Path Param:** `itemId` (string)
- **Response:** Chase race participants, progress, etc.
- **Flutter Call:** `ChaseRaceService.loadRace()` in `chase_race_service.dart`
- **Status:** ⚠️ Uncertain - Endpoint not confirmed in backend contract
- **Fallback:** Falls back to local cache; returns null if no cache and endpoint unavailable
- **Notes:** No fake data is injected; uses cache-first strategy with graceful degradation
- **TODO:** Confirm `/api/chase-race/*` endpoints are available in backend

---

## Bug Reports / Feedback

### POST /api/bugs/report
- **Purpose:** Submit a bug report or user feedback
- **Auth:** Optional (may be anonymous)
- **Body:** Report content, description, attachments, device info
- **Response:** Report submission confirmation
- **Flutter Call:** `BugReportService.submitReport()` in `bug_report_service.dart`
- **Status:** ✅ Confirmed

### GET /api/bugs/mine
- **Purpose:** Get current user's submitted bug reports and feedback
- **Auth:** Required
- **Query Params:** `page` (optional), `pageSize` (optional)
- **Response:** List of user's bug reports
- **Flutter Call:** `BugReportService.getMyReports()` in `bug_report_service.dart`
- **Status:** ✅ Confirmed

---

## Unsupported / Intentionally Disabled

### GET /api/adaptive/review (DEPRECATED)
- **Status:** ❌ REPLACED - Use `/api/adaptive/reviews/due` instead
- **Notes:** Old endpoint path; Flutter client updated to use new path in this release

### GET /api/analytics/mastery (UNAVAILABLE)
- **Status:** ❌ Backend does not provide this endpoint
- **Fallback:** Client returns empty list
- **Alternative:** Use `/api/adaptive/path` for mastery-like progress data
- **TODO:** Implement if backend adds this endpoint

### GET /api/leaderboard/rivals (DEPRECATED)
- **Status:** ❌ REPLACED - Use `/api/leaderboard/friends` instead
- **Notes:** Renamed for clarity; both return friend leaderboard data

### GET /api/chase/* (UNCONFIRMED)
- **Status:** ⚠️ Endpoint availability unconfirmed
- **Flutter Behavior:** Graceful fallback to local cache
- **TODO:** Confirm backend implements `/api/chase-race/{itemId}`

---

## Summary of Recent Changes

### Endpoint Path Updates
- `/api/users/{userId}/profile` → `/api/user/profile/{userId}` ✅
- `/api/adaptive/review` → `/api/adaptive/reviews/due` ✅
- `/api/leaderboard/rivals` → `/api/leaderboard/friends` ✅

### Payload/Parameter Updates
- `POST /api/adaptive/session/start`: Removed topicId/topic from request (not supported by backend yet)
- `POST /api/adaptive/session/answer`: Updated to use `adaptiveSessionId` + `adaptiveSessionItemId` (backward compatible)
- `GET /api/leaderboard/schools/history/{schoolId}`: Changed from `from`/`to` dates to `period` + `take` count

### Backend Gaps Handled
- `/api/analytics/mastery`: Returns empty list (endpoint unavailable)
- `/api/chase-race/*`: Graceful cache fallback (endpoint unconfirmed)

---

## Testing Recommendations

1. **Verify each endpoint** against backend implementation
2. **Test response shape normalization** (e.g., list vs. wrapped `items`/`data`)
3. **Validate backward compatibility** for deprecated parameters
4. **Check error handling** for unavailable endpoints (should gracefully degrade)
5. **Confirm authentication headers** are sent for all auth-required endpoints

---

## Contact / Owner

Backend API: MathLearning Backend Team  
Flutter Client: Mobile Development Team  
Last Updated: May 15, 2026

