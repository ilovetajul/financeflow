import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';
import '../../domain/models/transaction.dart' as model;

class DatabaseHelper {
  static final DatabaseHelper instance = DatabaseHelper._internal();
  static Database? _db;

  DatabaseHelper._internal();

  Future<Database> get database async {
    _db ??= await _initDatabase();
    return _db!;
  }

  Future<Database> _initDatabase() async {
    final path =
        join(await getDatabasesPath(), 'financeflow.db');
    return openDatabase(path, version: 1, onCreate: _onCreate);
  }

  Future<void> _onCreate(Database db, int version) async {
    await db.execute('''
      CREATE TABLE transactions (
        id TEXT PRIMARY KEY,
        type TEXT NOT NULL,
        category TEXT NOT NULL,
        amount REAL NOT NULL,
        note TEXT,
        date TEXT NOT NULL,
        icon TEXT NOT NULL
      )
    ''');
  }

  Future<List<model.Transaction>> getAllTransactions() async {
    final db = await database;
    final maps =
        await db.query('transactions', orderBy: 'date DESC');
    return maps.map(model.Transaction.fromJson).toList();
  }

  Future<void> insertTransaction(
      model.Transaction tx) async {
    final db = await database;
    await db.insert(
      'transactions',
      tx.toJson(),
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  // ── Update/Edit ─────────────────────────────────────────
  Future<void> updateTransaction(
      model.Transaction tx) async {
    final db = await database;
    await db.update(
      'transactions',
      tx.toJson(),
      where: 'id = ?',
      whereArgs: [tx.id],
    );
  }

  Future<void> deleteTransaction(String id) async {
    final db = await database;
    await db.delete(
        'transactions', where: 'id = ?', whereArgs: [id]);
  }

  Future<void> deleteAll() async {
    final db = await database;
    await db.delete('transactions');
  }

  Future<void> insertAll(
      List<model.Transaction> txs) async {
    final db = await database;
    final batch = db.batch();
    for (final tx in txs) {
      batch.insert(
        'transactions',
        tx.toJson(),
        conflictAlgorithm: ConflictAlgorithm.replace,
      );
    }
    await batch.commit(noResult: true);
  }
}
