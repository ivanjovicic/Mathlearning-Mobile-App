import 'package:drift/drift.dart';

class QuestionsTable extends Table {
  TextColumn get questionId => text()();
  TextColumn get userId => text()();
  IntColumn get topicId => integer().nullable()();
  IntColumn get subtopicId => integer().nullable()();
  TextColumn get contentJson => text()();
  TextColumn get contentHash => text().nullable()();
  TextColumn get sourceBundleId => text().nullable()();
  IntColumn get serverVersion => integer().withDefault(const Constant(1))();
  DateTimeColumn get cachedAt => dateTime()();
  DateTimeColumn get expiresAt => dateTime().nullable()();

  @override
  Set<Column<Object>>? get primaryKey => {questionId, userId};
}
