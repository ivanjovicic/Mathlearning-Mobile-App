# Mobile API Contract

## Canonical Quiz Endpoints
- `GET /api/quiz/questions`
- `POST /api/quiz/answer`

## Canonical Practice Flow
- `POST /api/practice/session/start`
- `POST /api/practice/session/{sessionId}/answer`
- `POST /api/practice/session/{sessionId}/complete`

## Valid Adaptive Content Endpoints
- `GET /api/adaptive/path`
- `GET /api/adaptive/reviews/due`
- `GET /api/adaptive/recommendations`

## Daily Run
- `POST /api/daily-run/chest/claim`

## Forbidden Runtime Endpoints
- `/api/adaptive/session/start`
- `/api/adaptive/session/answer`
- `/api/analytics/mastery`
- `/api/chase/`

## Note
Backend OpenAPI/codegen should eventually replace this manual contract.
