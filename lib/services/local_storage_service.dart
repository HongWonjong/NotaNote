import 'package:path/path.dart';
import 'package:path_provider/path_provider.dart';
import 'package:sqflite/sqflite.dart';
import 'dart:io';

class LocalStorageService {
  static final LocalStorageService _instance = LocalStorageService._internal();
  factory LocalStorageService() => _instance;
  LocalStorageService._internal();

  Database? _database;
  Map<String, String>? _imagePathCache;

  Future<Database> get database async {
    if (_database != null) return _database!;
    _database = await _initDatabase();
    await _initializeImagePathCache();
    return _database!;
  }

  Future<Database> _initDatabase() async {
    final directory = await getApplicationDocumentsDirectory();
    final path = join(directory.path, 'nota_note.db');
    return await openDatabase(
      path,
      version: 1,
      onCreate: (db, version) async {
        await db.execute('''
          CREATE TABLE images (
            id INTEGER PRIMARY KEY AUTOINCREMENT,
            groupId TEXT,
            noteId TEXT,
            pageId TEXT,
            imageUrl TEXT,
            localPath TEXT,
            formattingData TEXT
          )
        ''');
      },
    );
  }

  Future<void> _initializeImagePathCache() async {
    _imagePathCache = {};
    final db = await database;
    final result = await db.query('images');
    for (var row in result) {
      final groupId = row['groupId'] as String;
      final noteId = row['noteId'] as String;
      final pageId = row['pageId'] as String;
      final imageUrl = row['imageUrl'] as String;
      final localPath = row['localPath'] as String;
      if (await File(localPath).exists()) {
        _imagePathCache!['$groupId:$noteId:$pageId:$imageUrl'] = localPath;
      } else {
        await db.delete(
          'images',
          where: 'groupId = ? AND noteId = ? AND pageId = ? AND imageUrl = ?',
          whereArgs: [groupId, noteId, pageId, imageUrl],
        );
      }
    }
  }

  Future<String> getLocalImagePath(String groupId, String noteId, String pageId, String imageUrl) async {
    final db = await database;
    final result = await db.query(
      'images',
      where: 'groupId = ? AND noteId = ? AND pageId = ? AND imageUrl = ?',
      whereArgs: [groupId, noteId, pageId, imageUrl],
    );
    if (result.isNotEmpty) {
      final localPath = result.first['localPath'] as String;
      if (await File(localPath).exists()) {
        _imagePathCache ??= {};
        _imagePathCache!['$groupId:$noteId:$pageId:$imageUrl'] = localPath;
        return localPath;
      } else {
        await db.delete(
          'images',
          where: 'groupId = ? AND noteId = ? AND pageId = ? AND imageUrl = ?',
          whereArgs: [groupId, noteId, pageId, imageUrl],
        );
      }
    }
    return '';
  }

  String getLocalImagePathSync(String groupId, String noteId, String pageId, String imageUrl) {
    _imagePathCache ??= {};
    final cacheKey = '$groupId:$noteId:$pageId:$imageUrl';
    final cachedPath = _imagePathCache![cacheKey];
    if (cachedPath != null && File(cachedPath).existsSync()) {
      return cachedPath;
    }
    return '';
  }

  Future<Map<String, dynamic>?> getImageData(String groupId, String noteId, String pageId, String imageUrl) async {
    final db = await database;
    final result = await db.query(
      'images',
      where: 'groupId = ? AND noteId = ? AND pageId = ? AND imageUrl = ?',
      whereArgs: [groupId, noteId, pageId, imageUrl],
    );
    if (result.isNotEmpty) {
      return result.first;
    }
    return null;
  }

  Future<void> saveImageLocally({
    required String groupId,
    required String noteId,
    required String pageId,
    required String imageUrl,
    required String localPath,
    required String formattingData,
  }) async {
    final db = await database;
    await db.insert(
      'images',
      {
        'groupId': groupId,
        'noteId': noteId,
        'pageId': pageId,
        'imageUrl': imageUrl,
        'localPath': localPath,
        'formattingData': formattingData,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
    _imagePathCache ??= {};
    _imagePathCache!['$groupId:$noteId:$pageId:$imageUrl'] = localPath;
  }

  Future<String> saveImageFileToLocal(File imageFile, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final localPath = join(directory.path, 'images', fileName);
    final localFile = File(localPath);
    await localFile.create(recursive: true);
    await imageFile.copy(localPath);
    return localPath;
  }
}