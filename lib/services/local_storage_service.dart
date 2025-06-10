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
    print('Initializing SQLite database at: $path');
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
        print('Loaded cache: $localPath for $imageUrl');
      } else {
        print('Removing invalid cache entry: $localPath for $imageUrl');
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
        print('Found valid image in SQLite: $localPath for $imageUrl');
        _imagePathCache ??= {};
        _imagePathCache!['$groupId:$noteId:$pageId:$imageUrl'] = localPath;
        return localPath;
      } else {
        print('Invalid image file at: $localPath for $imageUrl, removing from SQLite');
        await db.delete(
          'images',
          where: 'groupId = ? AND noteId = ? AND pageId = ? AND imageUrl = ?',
          whereArgs: [groupId, noteId, pageId, imageUrl],
        );
      }
    } else {
      print('No image found in SQLite for: $imageUrl');
    }
    return '';
  }

  String getLocalImagePathSync(String groupId, String noteId, String pageId, String imageUrl) {
    _imagePathCache ??= {};
    final cacheKey = '$groupId:$noteId:$pageId:$imageUrl';
    final cachedPath = _imagePathCache![cacheKey];
    if (cachedPath != null && File(cachedPath).existsSync()) {
      print('Found valid image in cache: $cachedPath for $imageUrl');
      return cachedPath;
    }
    print('No cached image for: $imageUrl');
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
    print('Saved image to SQLite: $localPath for $imageUrl');
  }

  Future<String> saveImageFileToLocal(File imageFile, String fileName) async {
    final directory = await getApplicationDocumentsDirectory();
    final localPath = join(directory.path, 'images', fileName);
    final localFile = File(localPath);
    await localFile.create(recursive: true);
    await imageFile.copy(localPath);
    print('Saved image file to local storage: $localPath');
    return localPath;
  }
}