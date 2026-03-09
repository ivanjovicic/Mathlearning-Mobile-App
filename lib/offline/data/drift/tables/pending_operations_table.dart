import 'package:drift/drift.dart';

class PendingOperationsTable extends Table {
  TextColumn get operationId => text()();
  TextColumn get userId => text()();
  TextColumn get operationType => text()();
  TextColumn get entityType => text()();
  TextColumn get entityId => text()();
  TextColumn get payloadJson => text()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get updatedAt => dateTime()();
  IntColumn get retryCount => integer().withDefault(const Constant(0))();
  TextColumn get status => text().withDefault(const Constant('pending'))();
  DateTimeColumn get lastAttemptAt => dateTime().nullable()();
  DateTimeColumn get nextRetryAt => dateTime().nullable()();
  TextColumn get errorCode => text().nullable()();
  TextColumn get errorMessage => text().nullable()();
  TextColumn get idempotencyKey => text().customConstraint('NOT NULL UNIQUE')();
  TextColumn get dependsOnOperationId => text().nullable()();
  TextColumn get leaseOwner => text().nullable()();
  DateTimeColumn get leaseExpiresAt => dateTime().nullable()();
  IntColumn get priority => integer().withDefault(const Constant(100))();

  @override
  Set<Column<Object>>? get primaryKey => {operationId};
}
