# User-Scoped Storage Policy

## Why It Exists
User-scoped storage keeps one user's offline progress and rewards from leaking into another user's session after auth changes, restarts, or sync retries.

## What Must Be User-Scoped
- Progress cache
- Pending quiz answers
- Pending SRS updates
- Daily Run state
- Cosmetics and target state

## Why SessionCoordinator Does Not Auto-Delete Pending Data
Pending offline data can still be needed for sync after a user switch. Deleting it immediately risks losing quiz answers, SRS updates, or reward transactions before they are confirmed.

## Safe Cleanup Rule
Clear user-scoped data only after a successful sync or after an explicit clear-local-data action.

## Legacy Keys
Legacy global keys should be migrated conservatively into the new user-scoped hierarchy, then removed only when the migration path is safe and complete.
