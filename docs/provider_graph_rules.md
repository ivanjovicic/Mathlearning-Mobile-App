# Provider Graph Rules

- `ProxyProvider.update` must stay side-effect free.
- Auth/user-scoped async loading belongs in `SessionCoordinator`.
- Feature-specific loads belong in screen/provider methods.
- New API calls should use typed domain services, not `ApiService` wrappers.
