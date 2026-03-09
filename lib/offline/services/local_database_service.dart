import '../data/drift/app_offline_database.dart';

abstract class LocalDatabaseService {
  Future<AppOfflineDatabase> open();

  Future<void> close();

  bool get isSupported;
}
