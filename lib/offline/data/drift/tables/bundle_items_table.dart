import 'package:drift/drift.dart';

class BundleItemsTable extends Table {
  TextColumn get bundleId => text()();
  TextColumn get itemType => text()();
  TextColumn get itemId => text()();
  TextColumn get contentJson => text()();

  @override
  Set<Column<Object>>? get primaryKey => {bundleId, itemType, itemId};
}
