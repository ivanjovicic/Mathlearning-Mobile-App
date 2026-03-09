import '../../services/local_database_service.dart';
import 'app_offline_database.dart';

class DriftLocalDatabaseService implements LocalDatabaseService {
  AppOfflineDatabase? _database;

  @override
  bool get isSupported => true;

  @override
  Future<AppOfflineDatabase> open() async {
    _database ??= AppOfflineDatabase();
    return _database!;
  }

  @override
  Future<void> close() async {
    await _database?.close();
    _database = null;
  }
}
