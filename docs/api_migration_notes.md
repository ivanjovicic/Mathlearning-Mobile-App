# API Migration Notes

## Canonical practice flow

- `POST /api/practice/session/start`
- `POST /api/practice/session/{sessionId}/answer`
- `POST /api/practice/session/{sessionId}/complete`

## Adaptive content endpoints still valid

- `GET /api/adaptive/path`
- `GET /api/adaptive/reviews/due`
- `GET /api/adaptive/recommendations`

## Forbidden runtime endpoints

- `/api/adaptive/session/start`
- `/api/adaptive/session/answer`
- `/api/analytics/mastery`
- `/api/chase/`

## Notes

- `/api/analytics/mastery` is unsupported until backend defines a real mastery contract.
- `/api/chase/*` is unsupported until backend implements Chase Race.
- Daily Run chest rewards should become backend-authoritative through `POST /api/daily-run/chest/claim` when that backend endpoint exists.
