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
            duration INTEGER,
            createdAt TEXT
          )
        ''');
      },
    );
  }

  Future<void> insertRecording(RecordingInfo recording) async {
    final db = await database;
    await db.insert(
      'recordings',
      {
        'path': recording.path,
        'duration': recording.duration.inSeconds,
        'createdAt': recording.createdAt.toIso8601String(),
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  Future<List<RecordingInfo>> getAllRecordings() async {
    final db = await database;
    final maps = await db.query('recordings', orderBy: 'createdAt DESC');
    return maps.map((map) {
      return RecordingInfo(
        path: map['path'] as String,
        duration: Duration(seconds: map['duration'] as int),
        createdAt: DateTime.parse(map['createdAt'] as String),
      );
    }).toList();
  }

  Future<void> updateRecording(RecordingInfo recording) async {
    final db = await database;
    await db.update(
      'recordings',
      {
        'path': recording.path,
        'duration': recording.duration.inSeconds,
        'createdAt': recording.createdAt.toIso8601String(),
      },
      where: 'path = ?',
      whereArgs: [recording.path],
    );
  }

  Future<void> deleteRecording(String path) async {
    final db = await database;
    await db.delete(
      'recordings',
      where: 'path = ?',
      whereArgs: [path],
    );
  }
  Future<void> deleteAllRecordings() async {
    final db = await database;
    final recordings = await getAllRecordings();
    for (var recording in recordings) {
      final file = File(recording.path);
      if (await file.exists()) {
        await file.delete();
      }
    }
    await db.delete('recordings');
  }
}