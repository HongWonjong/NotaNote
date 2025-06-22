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
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE recordings (
            path TEXT PRIMARY KEY,
            userId TEXT,
            duration INTEGER,
            createdAt TEXT
          )
        ''');
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
        }
      }
      await db.delete(
        'recordings',
        where: 'userId = ?',
        whereArgs: [userId],
      );
    } catch (e) {
      print('Delete all recordings failed: $e');
    }
  }
}