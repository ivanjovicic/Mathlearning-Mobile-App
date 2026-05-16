import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'user_scoped_storage.dart';

class OfflineStorageService {
  static Database? _database;
  static const String _dbName = 'mathlearning_offline.db';
  static const int _version = 2;

  // Database tables
  static const String _questionsTable = 'questions';
  static const String _pendingAnswersTable = 'pending_answers';
  static const String _userProgressTable = 'user_progress';

  // SharedPreferences keys (used across platforms)
  static const String _srsDailyQuestionsKeyPrefix =
      'cached_srs_daily_questions_';
  static const String _srsDailyQuestionsUpdatedAtKeyPrefix =
      'cached_srs_daily_questions_updated_at_';
  static const String _pendingSrsUpdatesKeyPrefix = 'pending_srs_updates_';

  static Future<Database?> get database async {
    if (kIsWeb) {
      // SQLite doesn't work on web, return null for web fallback
      return null;
    }
    try {
      _database ??= await _initDB();
      return _database!;
    } catch (_) {
      // Widget tests and some platforms may run without a registered sqflite plugin.
      return null;
    }
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _version,
      onCreate: _createDB,
      onUpgrade: _upgradeDB,
    );
  }

  static Future _createDB(Database db, int version) async {
    // Table za čuvanje pitanja offline
    await db.execute('''
      CREATE TABLE $_questionsTable (
        id INTEGER PRIMARY KEY,
        subtopic_id INTEGER,
        text TEXT NOT NULL,
        correct_answer_id INTEGER NOT NULL,
        options TEXT NOT NULL,
        created_at INTEGER NOT NULL
      )
    ''');

    // Table za pending odgovore (dok nema interneta)
    await db.execute('''
      CREATE TABLE $_pendingAnswersTable (
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        quiz_id TEXT NOT NULL,
        question_id INTEGER NOT NULL,
        answer TEXT NOT NULL,
        time_spent_seconds INTEGER NOT NULL,
        timestamp INTEGER NOT NULL,
        is_correct INTEGER NOT NULL,
        user_id TEXT NOT NULL DEFAULT 'legacy'
      )
    ''');

    // Table za user progress cache
    await db.execute('''
      CREATE TABLE $_userProgressTable (
        id INTEGER PRIMARY KEY,
        level INTEGER NOT NULL,
        xp INTEGER NOT NULL,
        streak INTEGER NOT NULL,
        total_attempts INTEGER NOT NULL,
        accuracy REAL NOT NULL,
        last_updated INTEGER NOT NULL
      )
    ''');
  }

  static Future<void> _upgradeDB(
    Database db,
    int oldVersion,
    int newVersion,
  ) async {
    if (oldVersion < 2) {
      // Keep upgraded DB schema aligned with fresh installs.
      await db.execute(
        'ALTER TABLE $_pendingAnswersTable ADD COLUMN user_id TEXT NOT NULL DEFAULT \'legacy\'',
      );
    }
  }

  // === QUESTIONS OFFLINE CACHE ===

  static Future<void> cacheQuestions(
    int subtopicId,
    List<Map<String, dynamic>> questions,
  ) async {
    if (kIsWeb) {
      // Use SharedPreferences for web
      final prefs = await SharedPreferences.getInstance();
      final key = 'cached_questions_$subtopicId';
      await prefs.setString(key, jsonEncode(questions));
      return;
    }

    final db = await database;
    if (db == null) return;

    await db.transaction((txn) async {
      // Delete old questions for this subtopic
      await txn.delete(
        _questionsTable,
        where: 'subtopic_id = ?',
        whereArgs: [subtopicId],
      );

      // Insert new questions
      for (final question in questions) {
        await txn.insert(_questionsTable, {
          'id': question['id'],
          'subtopic_id': subtopicId,
          'text': question['text'],
          'correct_answer_id': question['correctAnswerId'],
          'options': jsonEncode(question['options']),
          'created_at': DateTime.now().millisecondsSinceEpoch,
        });
      }
    });
  }

  static Future<List<Map<String, dynamic>>?> getCachedQuestions(
    int subtopicId,
    int count,
  ) async {
    if (kIsWeb) {
      // Use SharedPreferences for web
      final prefs = await SharedPreferences.getInstance();
      final key = 'cached_questions_$subtopicId';
      final questionsJson = prefs.getString(key);
      if (questionsJson != null) {
        final questions = List<Map<String, dynamic>>.from(
          jsonDecode(questionsJson),
        );
        return questions.take(count).toList();
      }
      return null;
    }

    final db = await database;
    if (db == null) return null;

    final List<Map<String, dynamic>> maps = await db.query(
      _questionsTable,
      where: 'subtopic_id = ?',
      whereArgs: [subtopicId],
      limit: count,
      orderBy: 'RANDOM()',
    );

    if (maps.isEmpty) return null;

    return maps
        .map(
          (map) => {
            'id': map['id'],
            'text': map['text'],
            'correctAnswerId': map['correct_answer_id'],
            'subtopicId': map['subtopic_id'],
            'options': jsonDecode(map['options']),
          },
        )
        .toList();
  }

  // === PENDING ANSWERS (for batch submit) ===

  static Future<void> savePendingAnswer({
    required String quizId,
    required int questionId,
    required String answer,
    required int timeSpentSeconds,
    required bool isCorrect,
    required String userId,
  }) async {
    if (kIsWeb) {
      // Use SharedPreferences for web
      final prefs = await SharedPreferences.getInstance();
      final pendingAnswers = await getPendingAnswers();
      pendingAnswers.add({
        'quiz_id': quizId,
        'question_id': questionId,
        'answer': answer,
        'time_spent_seconds': timeSpentSeconds,
        'timestamp': DateTime.now().millisecondsSinceEpoch,
        'is_correct': isCorrect ? 1 : 0,
        'user_id': userId,
      });
      final saved = await prefs.setString(
        'pending_answers',
        jsonEncode(pendingAnswers),
      );
      if (!saved) {
        throw StateError('Failed to persist pending_answers in SharedPreferences');
      }
      return;
    }

    final db = await database;
    if (db == null) {
      throw StateError('Offline SQLite storage is unavailable');
    }

    await db.insert(_pendingAnswersTable, {
      'quiz_id': quizId,
      'question_id': questionId,
      'answer': answer,
      'time_spent_seconds': timeSpentSeconds,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'is_correct': isCorrect ? 1 : 0,
      'user_id': userId,
    });
  }

  static Future<List<Map<String, dynamic>>> getPendingAnswers({
    String? userId,
  }) async {
    if (kIsWeb) {
      // Use SharedPreferences for web
      final prefs = await SharedPreferences.getInstance();
      final pendingAnswersJson = prefs.getString('pending_answers');
      if (pendingAnswersJson != null) {
        final all = List<Map<String, dynamic>>.from(jsonDecode(pendingAnswersJson));
        if (userId == null) return all;
        return all.where((answer) => _pendingAnswerMatchesUserId(answer, userId)).toList();
      }
      return [];
    }

    final db = await database;
    if (db == null) return [];

    final rows = await db.query(_pendingAnswersTable, orderBy: 'timestamp ASC');
    if (userId == null) return rows;
    return rows.where((answer) => _pendingAnswerMatchesUserId(answer, userId)).toList();
  }

  static Future<void> clearPendingAnswers({String? userId}) async {
    if (kIsWeb) {
      // Use SharedPreferences for web
      final prefs = await SharedPreferences.getInstance();
      if (userId == null) {
        await prefs.remove('pending_answers');
        return;
      }

      final pendingAnswers = await getPendingAnswers();
      final remaining = pendingAnswers
          .where((answer) => !_pendingAnswerMatchesUserId(answer, userId))
          .toList();
      await prefs.setString('pending_answers', jsonEncode(remaining));
      return;
    }

    final db = await database;
    if (db == null) return;

    if (userId == null) {
      await db.delete(_pendingAnswersTable);
      return;
    }

    final args = <Object?>[userId];
    final where =
        'user_id = ?${_shouldIncludeLegacyPendingAnswers(userId) ? " OR user_id IS NULL OR user_id = 'legacy'" : ""}';
    await db.delete(_pendingAnswersTable, where: where, whereArgs: args);
  }

  static bool _shouldIncludeLegacyPendingAnswers(String userId) {
    return userId == 'local' || userId == 'default';
  }

  static bool _pendingAnswerMatchesUserId(
    Map<String, dynamic> answer,
    String userId,
  ) {
    final answerUserId = answer['user_id']?.toString();
    if (answerUserId == userId) return true;
    if (_shouldIncludeLegacyPendingAnswers(userId)) {
      return answerUserId == null || answerUserId == 'legacy';
    }
    return false;
  }

  // === USER PROGRESS CACHE ===

  static Future<void> cacheUserProgress({
    required int level,
    required int xp,
    required int streak,
    required int totalAttempts,
    required double accuracy,
  }) async {
    await cacheUserProgressForUser(
      userId: 'local',
      level: level,
      xp: xp,
      streak: streak,
      totalAttempts: totalAttempts,
      accuracy: accuracy,
    );
  }

  static Future<void> cacheUserProgressForUser({
    required String userId,
    required int level,
    required int xp,
    required int streak,
    required int totalAttempts,
    required double accuracy,
  }) async {
    final progressData = {
      'level': level,
      'xp': xp,
      'streak': streak,
      'total_attempts': totalAttempts,
      'accuracy': accuracy,
      'last_updated': DateTime.now().millisecondsSinceEpoch,
    };

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_userProgressKey(userId), jsonEncode(progressData));

    if (kIsWeb || UserScopedStorage.normalizeUserId(userId) != 'local') {
      return;
    }

    final db = await database;
    if (db == null) return;
    await db.insert(_userProgressTable, {
      'id': 1, // Always use ID 1 for current user
      'level': level,
      'xp': xp,
      'streak': streak,
      'total_attempts': totalAttempts,
      'accuracy': accuracy,
      'last_updated': DateTime.now().millisecondsSinceEpoch,
    }, conflictAlgorithm: ConflictAlgorithm.replace);
  }

  static Future<Map<String, dynamic>?> getCachedUserProgress() async {
    return getCachedUserProgressForUser(userId: 'local');
  }

  static Future<Map<String, dynamic>?> getCachedUserProgressForUser({
    required String userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final normalizedUserId = UserScopedStorage.normalizeUserId(userId);
    final scopedProgressJson = prefs.getString(_userProgressKey(userId));
    if (scopedProgressJson != null) {
      return Map<String, dynamic>.from(jsonDecode(scopedProgressJson));
    }

    if (normalizedUserId != 'local') {
      return null;
    }

    final legacyProgressJson = prefs.getString('user_progress');
    if (legacyProgressJson != null) {
      return Map<String, dynamic>.from(jsonDecode(legacyProgressJson));
    }

    if (kIsWeb) {
      return null;
    }

    final db = await database;
    if (db == null) return null;

    final List<Map<String, dynamic>> maps = await db.query(
      _userProgressTable,
      where: 'id = ?',
      whereArgs: [1],
    );

    return maps.isNotEmpty ? maps.first : null;
  }

  // === SRS DAILY QUESTIONS CACHE (SharedPreferences) ===

  static Future<void> cacheDailySrsQuestions({
    required String userId,
    required List<Map<String, dynamic>> questions,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(
      '$_srsDailyQuestionsKeyPrefix$userId',
      jsonEncode(questions),
    );
    await prefs.setInt(
      '$_srsDailyQuestionsUpdatedAtKeyPrefix$userId',
      DateTime.now().millisecondsSinceEpoch,
    );
  }

  static Future<List<Map<String, dynamic>>> getCachedDailySrsQuestions({
    required String userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_srsDailyQuestionsKeyPrefix$userId');
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return List<Map<String, dynamic>>.from(decoded);
      }
    } catch (_) {
      // Corrupted cache - ignore.
    }

    return [];
  }

  static Future<DateTime?> getCachedDailySrsQuestionsUpdatedAt({
    required String userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final ms = prefs.getInt('$_srsDailyQuestionsUpdatedAtKeyPrefix$userId');
    if (ms == null) return null;
    return DateTime.fromMillisecondsSinceEpoch(ms);
  }

  static Future<void> clearDailySrsQuestionsCache({
    required String userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_srsDailyQuestionsKeyPrefix$userId');
    await prefs.remove('$_srsDailyQuestionsUpdatedAtKeyPrefix$userId');
  }

  // === PENDING SRS UPDATES QUEUE (SharedPreferences) ===

  static Future<void> savePendingSrsUpdate({
    required String userId,
    required int questionId,
    required bool isCorrect,
    required int timeMs,
  }) async {
    final pending = await getPendingSrsUpdates(userId: userId);
    pending.add({
      'questionId': questionId,
      'isCorrect': isCorrect,
      'timeMs': timeMs,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
    });
    await replacePendingSrsUpdates(userId: userId, updates: pending);
  }

  static Future<List<Map<String, dynamic>>> getPendingSrsUpdates({
    required String userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString('$_pendingSrsUpdatesKeyPrefix$userId');
    if (raw == null || raw.isEmpty) return [];

    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return List<Map<String, dynamic>>.from(decoded);
      }
    } catch (_) {
      // Corrupted queue - ignore.
    }

    return [];
  }

  static Future<void> replacePendingSrsUpdates({
    required String userId,
    required List<Map<String, dynamic>> updates,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = '$_pendingSrsUpdatesKeyPrefix$userId';
    if (updates.isEmpty) {
      await prefs.remove(key);
      return;
    }
    await prefs.setString(key, jsonEncode(updates));
  }

  static Future<int> getPendingSrsUpdatesCount({required String userId}) async {
    final pending = await getPendingSrsUpdates(userId: userId);
    return pending.length;
  }

  static Future<void> clearPendingSrsUpdates({required String userId}) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('$_pendingSrsUpdatesKeyPrefix$userId');
  }

  // === GENERIC V1-KEYED CACHE (SharedPreferences, cross-platform) ===

  static const String _keyPendingAnswersV1 = 'offline_pending_answers_v1';
  static const String _keyPendingSrsV1 = 'offline_pending_srs_v1';
  static const String _keyCachedQuestionsV1 = 'offline_cached_questions_v1';
  static const String _keyCachedSrsDailyV1 = 'offline_cached_srs_daily_v1';
  static const String _keyCachedProgressV1 = 'offline_cached_progress_v1';
  static const String _keyPendingProgressEvents = 'pending_progress_events_v1';

  // ---------- V1 Pending Answers ----------
  static Future<void> savePendingAnswersV1(
    List<Map<String, dynamic>> list,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPendingAnswersV1, jsonEncode(list));
  }

  static Future<List<Map<String, dynamic>>> loadPendingAnswersV1() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyPendingAnswersV1);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  // ---------- V1 Pending SRS ----------
  static Future<void> savePendingSrsV1(List<Map<String, dynamic>> list) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyPendingSrsV1, jsonEncode(list));
  }

  static Future<List<Map<String, dynamic>>> loadPendingSrsV1() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyPendingSrsV1);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  // ---------- V1 Cached Questions ----------
  static Future<void> cacheQuestionsV1(
    List<Map<String, dynamic>> questions,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCachedQuestionsV1, jsonEncode(questions));
  }

  static Future<List<Map<String, dynamic>>> loadCachedQuestionsV1() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyCachedQuestionsV1);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  // ---------- V1 Cached SRS Daily ----------
  static Future<void> cacheSrsDailyV1(
    List<Map<String, dynamic>> questions,
  ) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyCachedSrsDailyV1, jsonEncode(questions));
  }

  static Future<List<Map<String, dynamic>>> loadCachedSrsDailyV1() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_keyCachedSrsDailyV1);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw) as List<dynamic>;
      return decoded.cast<Map<String, dynamic>>();
    } catch (_) {
      return [];
    }
  }

  // ---------- V1 Cached Progress (XP/Streak) ----------
  static Future<void> cacheProgressV1(Map<String, dynamic> progress) async {
    await cacheProgressV1ForUser(userId: 'local', progress: progress);
  }

  static Future<void> cacheProgressV1ForUser({
    required String userId,
    required Map<String, dynamic> progress,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_cachedProgressV1Key(userId), jsonEncode(progress));
  }

  static Future<Map<String, dynamic>?> loadCachedProgressV1() async {
    return loadCachedProgressV1ForUser(userId: 'local');
  }

  static Future<Map<String, dynamic>?> loadCachedProgressV1ForUser({
    required String userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw =
        prefs.getString(_cachedProgressV1Key(userId)) ??
        (UserScopedStorage.normalizeUserId(userId) == 'local'
            ? prefs.getString(_keyCachedProgressV1)
            : null);
    if (raw == null) return null;
    try {
      return jsonDecode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  // ---------- Pending Progress Events (for offline optimistic updates) ----------
  static Future<void> cachePendingProgressEvents(
    List<Map<String, dynamic>> events,
  ) async {
    await cachePendingProgressEventsForUser(userId: 'local', events: events);
  }

  static Future<void> cachePendingProgressEventsForUser({
    required String userId,
    required List<Map<String, dynamic>> events,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final key = _pendingProgressEventsKey(userId);
    if (events.isEmpty) {
      await prefs.remove(key);
      return;
    }
    await prefs.setString(key, jsonEncode(events));
  }

  static Future<List<Map<String, dynamic>>> loadPendingProgressEvents() async {
    return loadPendingProgressEventsForUser(userId: 'local');
  }

  static Future<List<Map<String, dynamic>>> loadPendingProgressEventsForUser({
    required String userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final raw =
        prefs.getString(_pendingProgressEventsKey(userId)) ??
        (UserScopedStorage.normalizeUserId(userId) == 'local'
            ? prefs.getString(_keyPendingProgressEvents)
            : null);
    if (raw == null) return [];
    try {
      final decoded = jsonDecode(raw);
      if (decoded is List) {
        return decoded.whereType<Map<String, dynamic>>().toList(
          growable: false,
        );
      }
    } catch (_) {
      // corrupted
    }
    return [];
  }

  static Future<void> clearPendingProgressEvents() async {
    await clearPendingProgressEventsForUser(userId: 'local');
  }

  static Future<void> clearPendingProgressEventsForUser({
    required String userId,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_pendingProgressEventsKey(userId));
  }

  static String _userProgressKey(String userId) =>
      UserScopedStorage.scopedKey(userId, 'progress', 'snapshot');

  static String _cachedProgressV1Key(String userId) =>
      UserScopedStorage.scopedKey(userId, 'progress', 'cached_v1');

  static String _pendingProgressEventsKey(String userId) =>
      UserScopedStorage.scopedKey(userId, 'progress', 'pending_events_v1');
}
