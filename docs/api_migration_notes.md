# API Migration Notes — Legacy adaptive session endpoints

Date: 2026-05-15

Summary
-------
The Flutter client runtime has removed the legacy adaptive session methods that previously lived on `ApiService`:

- `startAdaptiveSession`
- `startAdaptiveSessionResult`
- `submitAdaptiveSessionAnswer`
- `submitAdaptiveSessionAnswerResult`

These methods were removed from the client runtime in commit `fa451ad`. Client code must now use the canonical practice session flow.

Canonical practice-session endpoints (use these from the client)
----------------------------------------------------------------
- `POST /api/practice/session/start` — start a practice session
- `POST /api/practice/session/{sessionId}/answer` — submit an answer
- `POST /api/practice/session/{sessionId}/complete` — complete a session

Client migration guidance
------------------------
1. Replace legacy session calls with `PracticeSessionApiService`:

   - Start a session:
     - Call `PracticeSessionApiService.startSession(PracticeStartRequest)`
     - Request body (example): `{'skillNodeId', 'topicId', 'subtopicId', 'targetQuestions', 'preferredDifficulty'}`

   - Submit an answer:
     - Call `PracticeSessionApiService.submitAnswer(sessionId, PracticeAnswerRequest)`
     - Request body (example): `{'questionId', 'selectedOption', 'timeSpentMs'}`

   - Complete a session:
     - Call `PracticeSessionApiService.completeSession(sessionId)`

2. If your code relied on the old `/api/adaptive/session/start` response shape (for example a `sessionId` plus a list of `questions`), adapt the flow to use the `PracticeStartResponse` returned by `PracticeSessionApiService.startSession()` (this contains `sessionId`, `question`, `initialMastery`, and other fields).

3. The following adaptive endpoints remain valid and are not part of the practice-session removal:

   - `GET /api/adaptive/path` — full adaptive learning path (learning-map features)
   - `GET /api/adaptive/reviews/due` — review items due

   These are used for the learning path and review features and should not be confused with the (removed) adaptive *session* start/answer flow.

4. Repo safeguard
-----------------
This repository includes a guard unit test, `test/guards/forbidden_adaptive_session_endpoints_test.dart`, which will fail if any runtime code in `lib/` references the legacy session endpoints (`/api/adaptive/session/start` or `/api/adaptive/session/answer`).

If you need help migrating a specific caller, open a PR that replaces the legacy call with `PracticeSessionApiService` and run the guard test.

Contact
-------
If server-side behavior or payload mapping is required to make the migration smooth, coordinate with the backend team. Provide examples of the old payload and the new `/api/practice/session/start` payload so the backend can support compatibility if necessary.
