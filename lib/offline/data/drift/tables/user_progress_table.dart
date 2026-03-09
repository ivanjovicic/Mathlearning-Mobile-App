import 'package:drift/drift.dart';

class UserProgressTable extends Table {
  TextColumn get userId => text()();
  IntColumn get level => integer().withDefault(const Constant(1))();
  IntColumn get xp => integer().withDefault(const Constant(0))();
  IntColumn get streak => integer().withDefault(const Constant(0))();
  IntColumn get totalAttempts => integer().withDefault(const Constant(0))();
  RealColumn get accuracy => real().withDefault(const Constant(0))();
  DateTimeColumn get serverUpdatedAt => dateTime().nullable()();
  DateTimeColumn get localUpdatedAt => dateTime()();
  BoolColumn get dirty => boolean().withDefault(const Constant(false))();

  @override
  Set<Column<Object>>? get primaryKey => {userId};
}
