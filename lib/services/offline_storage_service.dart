import 'dart:convert';
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OfflineStorageService {
  static Database? _database;
  static const String _dbName = 'mathlearning_offline.db';
  static const int _version = 1;

  // Database tables
  static const String _questionsTable = 'questions';
  static const String _pendingAnswersTable = 'pending_answers';
  static const String _userProgressTable = 'user_progress';

  static Future<Database?> get database async {
    if (kIsWeb) {
      // SQLite doesn't work on web, return null for web fallback
      return null;
    }
    _database ??= await _initDB();
    return _database!;
  }

  static Future<Database> _initDB() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, _dbName);

    return await openDatabase(
      path,
      version: _version,
      onCreate: _createDB,
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
        is_correct INTEGER NOT NULL
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

  // === QUESTIONS OFFLINE CACHE ===
  
  static Future<void> cacheQuestions(int subtopicId, List<Map<String, dynamic>> questions) async {
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
      await txn.delete(_questionsTable, where: 'subtopic_id = ?', whereArgs: [subtopicId]);
      
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

  static Future<List<Map<String, dynamic>>?> getCachedQuestions(int subtopicId, int count) async {
    if (kIsWeb) {
      // Use SharedPreferences for web
      final prefs = await SharedPreferences.getInstance();
      final key = 'cached_questions_$subtopicId';
      final questionsJson = prefs.getString(key);
      if (questionsJson != null) {
        final questions = List<Map<String, dynamic>>.from(jsonDecode(questionsJson));
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

    return maps.map((map) => {
      'id': map['id'],
      'text': map['text'],
      'correctAnswerId': map['correct_answer_id'],
      'subtopicId': map['subtopic_id'],
      'options': jsonDecode(map['options']),
    }).toList();
  }

  // === PENDING ANSWERS (for batch submit) ===
  
  static Future<void> savePendingAnswer({
    required String quizId,
    required int questionId,
    required String answer,
    required int timeSpentSeconds,
    required bool isCorrect,
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
      });
      await prefs.setString('pending_answers', jsonEncode(pendingAnswers));
      return;
    }
    
    final db = await database;
    if (db == null) return;
    
    await db.insert(_pendingAnswersTable, {
      'quiz_id': quizId,
      'question_id': questionId,
      'answer': answer,
      'time_spent_seconds': timeSpentSeconds,
      'timestamp': DateTime.now().millisecondsSinceEpoch,
      'is_correct': isCorrect ? 1 : 0,
    });
  }

  static Future<List<Map<String, dynamic>>> getPendingAnswers() async {
    if (kIsWeb) {
      // Use SharedPreferences for web
      final prefs = await SharedPreferences.getInstance();
      final pendingAnswersJson = prefs.getString('pending_answers');
      if (pendingAnswersJson != null) {
        return List<Map<String, dynamic>>.from(jsonDecode(pendingAnswersJson));
      }
      return [];
    }
    
    final db = await database;
    if (db == null) return [];
    
    return await db.query(_pendingAnswersTable, orderBy: 'timestamp ASC');
  }

  static Future<void> clearPendingAnswers() async {
    if (kIsWeb) {
      // Use SharedPreferences for web
      final prefs = await SharedPreferences.getInstance();
      await prefs.remove('pending_answers');
      return;
    }
    
    final db = await database;
    if (db == null) return;
    await db.delete(_pendingAnswersTable);
  }

  // === USER PROGRESS CACHE ===
  
  static Future<void> cacheUserProgress({
    required int level,
    required int xp,
    required int streak,
    required int totalAttempts,
    required double accuracy,
  }) async {
    if (kIsWeb) {
      // Use SharedPreferences for web
      final prefs = await SharedPreferences.getInstance();
      final progressData = {
        'level': level,
        'xp': xp,
        'streak': streak,
        'total_attempts': totalAttempts,
        'accuracy': accuracy,
        'last_updated': DateTime.now().millisecondsSinceEpoch,
      };
      await prefs.setString('user_progress', jsonEncode(progressData));
      return;
    }
    
    final db = await database;
    if (db == null) return;
    
    await db.insert(
      _userProgressTable,
      {
        'id': 1, // Always use ID 1 for current user
        'level': level,
        'xp': xp,
        'streak': streak,
        'total_attempts': totalAttempts,
        'accuracy': accuracy,
        'last_updated': DateTime.now().millisecondsSinceEpoch,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  static Future<Map<String, dynamic>?> getCachedUserProgress() async {
    if (kIsWeb) {
      // Use SharedPreferences for web
      final prefs = await SharedPreferences.getInstance();
      final progressJson = prefs.getString('user_progress');
      if (progressJson != null) {
        return Map<String, dynamic>.from(jsonDecode(progressJson));
      }
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
}