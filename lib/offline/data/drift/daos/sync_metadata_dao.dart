import 'package:drift/drift.dart';

import '../app_offline_database.dart';
import '../tables/sync_metadata_table.dart';

part 'sync_metadata_dao.g.dart';

@DriftAccessor(tables: [SyncMetadataTable])
class SyncMetadataDao extends DatabaseAccessor<AppOfflineDatabase>
    with _$SyncMetadataDaoMixin {
  SyncMetadataDao(super.db);

  Future<void> upsertValue({
    required String key,
    required String valueJson,
    required DateTime updatedAt,
  }) {
    return into(syncMetadataTable).insertOnConflictUpdate(
      SyncMetadataTableCompanion(
        key: Value(key),
        valueJson: Value(valueJson),
        updatedAt: Value(updatedAt),
      ),
    );
  }

  Future<SyncMetadataTableData?> readValue(String key) {
    return (select(syncMetadataTable)..where((tbl) => tbl.key.equals(key)))
        .getSingleOrNull();
  }
}
