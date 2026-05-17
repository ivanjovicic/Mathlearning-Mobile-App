# User-Scoped Storage Policy

Pending offline data is user-scoped to prevent cross-account leakage and preserve replay correctness per user.

## What Must Be User-Scoped
- Pending quiz answers
- Pending SRS updates
- Cached daily/user progress snapshots
- Transactional daily-run state and claim progress

## Auth Switch Behavior
- Auth/user switch does **not** automatically delete pending data.
- Rationale: pending work may still need replay for the originating user/session.

## Clearing Policy
- Clear pending data only after successful sync, or
- Clear via explicit user action (clear local data).
