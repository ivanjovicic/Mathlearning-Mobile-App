# Mobile API Contract

This document defines runtime mobile endpoints currently supported by the app.

## Quiz
- `GET /api/quiz/questions`
- `POST /api/quiz/answer`

## Practice
- `POST /api/practice/session/start`
- `POST /api/practice/session/{sessionId}/answer`
- `POST /api/practice/session/{sessionId}/complete`

## Adaptive Content
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
