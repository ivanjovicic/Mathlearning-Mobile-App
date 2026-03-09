import 'dart:io';

import 'package:drift/drift.dart';
import 'package:drift/native.dart';
import 'package:path/path.dart' as path;
import 'package:sqflite/sqflite.dart' as sqflite;

import 'daos/pending_operations_dao.dart';
import 'daos/sync_metadata_dao.dart';
import 'tables/bundle_items_table.dart';
import 'tables/content_bundles_table.dart';
import 'tables/pending_operations_table.dart';
import 'tables/questions_table.dart';
import 'tables/sync_metadata_table.dart';
import 'tables/user_progress_table.dart';

part 'app_offline_database.g.dart';

@DriftDatabase(
  tables: [
    QuestionsTable,
    UserProgressTable,
    PendingOperationsTable,
    SyncMetadataTable,
    ContentBundlesTable,
    BundleItemsTable,
  ],
  daos: [
    PendingOperationsDao,
    SyncMetadataDao,
  ],
)
class AppOfflineDatabase extends _$AppOfflineDatabase {
  AppOfflineDatabase() : super(_openConnection());

  AppOfflineDatabase.test(super.executor);

  @override
  int get schemaVersion => 1;

  @override
  MigrationStrategy get migration => MigrationStrategy(
        onCreate: (migrator) async {
          await migrator.createAll();
          await _createIndexes();
        },
        onUpgrade: (migrator, from, to) async {
          if (from < 1) {
            await migrator.createAll();
          }
          await _createIndexes();
        },
      );

  Future<void> _createIndexes() async {
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_questions_user_topic '
      'ON questions_table (user_id, topic_id)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_questions_expires '
      'ON questions_table (expires_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_pending_status_retry '
      'ON pending_operations_table (status, next_retry_at)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_pending_user_status '
      'ON pending_operations_table (user_id, status)',
    );
    await customStatement(
      'CREATE INDEX IF NOT EXISTS idx_bundles_user_type '
      'ON content_bundles_table (user_id, bundle_type)',
    );
  }

  static QueryExecutor _openConnection() {
    return LazyDatabase(() async {
      final dbFolder = await sqflite.getDatabasesPath();
      final file = File(path.join(dbFolder, 'mathlearning_offline_v2.sqlite'));
      return NativeDatabase.createInBackground(file);
    });
  }
}
