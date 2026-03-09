enum OfflineBundleStatus {
  notDownloaded,
  downloading,
  ready,
  stale,
  failed,
}

class OfflineBundleDescriptor {
  const OfflineBundleDescriptor({
    required this.bundleId,
    required this.userId,
    required this.bundleType,
    required this.version,
    required this.status,
    required this.expiresAt,
    required this.sizeBytes,
    required this.createdAt,
    required this.updatedAt,
  });

  final String bundleId;
  final String userId;
  final String bundleType;
  final String version;
  final OfflineBundleStatus status;
  final DateTime expiresAt;
  final int sizeBytes;
  final DateTime createdAt;
  final DateTime updatedAt;
}
