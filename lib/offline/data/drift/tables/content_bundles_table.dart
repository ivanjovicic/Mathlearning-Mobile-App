import 'package:drift/drift.dart';

class ContentBundlesTable extends Table {
  TextColumn get bundleId => text()();
  TextColumn get userId => text()();
  TextColumn get bundleType => text()();
  TextColumn get version => text()();
  TextColumn get downloadStatus => text()();
  DateTimeColumn get expirationTimestamp => dateTime()();
  IntColumn get sizeBytes => integer().withDefault(const Constant(0))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();

  @override
  Set<Column<Object>>? get primaryKey => {bundleId};
}
