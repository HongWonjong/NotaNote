import 'dart:io';
import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'package:nota_note/viewmodels/recording_viewmodel.dart';

class RecordingLocalStorageService {
  Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'recordings.db');
    return await openDatabase(
      path,
      version: 2,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE recordings (
            path TEXT PRIMARY KEY,
            userId TEXT,
            duration INTEGER,
            createdAt TEXT
          )
        ''');
        await db.execute('''
          CREATE TABLE sync_info (
            userId TEXT PRIMARY KEY,
            lastSyncedAt TEXT
          )
        ''');
      },
      onUpgrade: (db, oldVersion, newVersion) async {
        if (oldVersion < 2) {
          await db.execute('''
            CREATE TABLE IF NOT EXISTS recordings (
              path TEXT PRIMARY KEY,
              userId TEXT,
              duration INTEGER,
              createdAt TEXT
            )
          ''');
          await db.execute('''
            CREATE TABLE IF NOT EXISTS sync_info (
              userId TEXT PRIMARY KEY,
              lastSyncedAt TEXT
            )
          ''');
          // 기존 데이터 마이그레이션
          try {
            await db.execute('ALTER TABLE recordings ADD COLUMN userId TEXT');
          } catch (e) {
            print('Migration failed: $e');
          }
        }
      },
    );
  }

  Future<void> insertRecording(String userId, RecordingInfo recording) async {
    try {
      final db = await database;
      await db.insert(
        'recordings',
        {
          'path': recording.path,
          'userId': userId,
          'duration': recording.duration.inSeconds,
          'createdAt': recording.createdAt.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('Inserted recording to local DB: ${recording.path}');
    } catch (e) {
      print('Insert recording failed: $e');
    }
  }

  Future<List<RecordingInfo>> getAllRecordings(String userId) async {
    try {
      final db = await database;
      final maps = await db.query(
        'recordings',
        where: 'userId = ?',
        whereArgs: [userId],
        orderBy: 'createdAt DESC',
      );
      return maps.map((map) {
        return RecordingInfo(
          path: map['path'] as String,
          duration: Duration(seconds: map['duration'] as int),
          createdAt: DateTime.parse(map['createdAt'] as String),
        );
      }).toList();
    } catch (e) {
      print('Get all recordings failed: $e');
      return [];
    }
  }

  Future<List<RecordingInfo>> getRecordingsSince(String userId, DateTime? lastSyncedAt) async {
    try {
      final db = await database;
      final maps = await db.query(
        'recordings',
        where: 'userId = ?' + (lastSyncedAt != null ? ' AND createdAt > ?' : ''),
        whereArgs: lastSyncedAt != null ? [userId, lastSyncedAt.toIso8601String()] : [userId],
        orderBy: 'createdAt DESC',
      );
      return maps.map((map) {
        return RecordingInfo(
          path: map['path'] as String,
          duration: Duration(seconds: map['duration'] as int),
          createdAt: DateTime.parse(map['createdAt'] as String),
        );
      }).toList();
    } catch (e) {
      print('Get recordings since failed: $e');
      return [];
    }
  }

  Future<RecordingInfo?> getRecordingByPath(String userId, String path) async {
    try {
      final db = await database;
      final maps = await db.query(
        'recordings',
        where: 'userId = ? AND path = ?',
        whereArgs: [userId, path],
      );
      if (maps.isEmpty) return null;
      return RecordingInfo(
        path: maps[0]['path'] as String,
        duration: Duration(seconds: maps[0]['duration'] as int),
        createdAt: DateTime.parse(maps[0]['createdAt'] as String),
      );
    } catch (e) {
      print('Get recording by path failed: $e');
      return null;
    }
  }

  Future<void> updateRecording(String userId, RecordingInfo recording) async {
    try {
      final db = await database;
      await db.update(
        'recordings',
        {
          'path': recording.path,
          'userId': userId,
          'duration': recording.duration.inSeconds,
          'createdAt': recording.createdAt.toIso8601String(),
        },
        where: 'userId = ? AND path = ?',
        whereArgs: [userId, recording.path],
      );
    } catch (e) {
      print('Update recording failed: $e');
    }
  }

  Future<void> deleteRecording(String userId, String path) async {
    try {
      final db = await database;
      await db.delete(
        'recordings',
        where: 'userId = ? AND path = ?',
        whereArgs: [userId, path],
      );
      print('Deleted recording from local DB: $path');
    } catch (e) {
      print('Delete recording failed: $e');
    }
  }

  Future<void> deleteAllRecordings(String userId) async {
    try {
      final db = await database;
      final recordings = await getAllRecordings(userId);
      for (var recording in recordings) {
        final file = File(recording.path);
        if (await file.exists()) {
          await file.delete();
          print('Deleted local file: ${recording.path}');
        }
      }
      await db.delete(
        'recordings',
        where: 'userId = ?',
        whereArgs: [userId],
      );
      print('Deleted all recordings from local DB for user: $userId');
    } catch (e) {
      print('Delete all recordings failed: $e');
    }
  }

  Future<DateTime?> getLastSyncedAt(String userId) async {
    try {
      final db = await database;
      final maps = await db.query(
        'sync_info',
        where: 'userId = ?',
        whereArgs: [userId],
      );
      if (maps.isEmpty) return null;
      return DateTime.parse(maps[0]['lastSyncedAt'] as String);
    } catch (e) {
      print('Get last synced at failed: $e');
      return null;
    }
  }

  Future<void> setLastSyncedAt(String userId, DateTime time) async {
    try {
      final db = await database;
      await db.insert(
        'sync_info',
        {
          'userId': userId,
          'lastSyncedAt': time.toIso8601String(),
        },
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
      print('Set last synced at: $time for user: $userId');
    } catch (e) {
      print('Set last synced at failed: $e');
    }
  }
}