# Provider Graph Rules

1. `Provider.update` callbacks must stay side-effect free.
2. No network calls, `SharedPreferences` workflows, or `unawaited` async loads from `ProxyProvider.update`.
3. Auth/user-scoped loading belongs in `SessionCoordinator`.
4. Feature-specific explicit loads belong in screen or provider methods.
5. New API dependencies should use typed domain services, not `ApiService` wrappers.
