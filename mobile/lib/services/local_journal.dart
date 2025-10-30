import 'dart:async';
import 'package:sqflite/sqflite.dart';
import 'package:path/path.dart';

class LocalJournal {
  static Database? _db;

  Future<Database> get db async {
    if (_db != null) return _db!;
    _db = await _initDb();
    return _db!;
  }

  Future<Database> _initDb() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, 'ledger.db');
    return await openDatabase(path, version: 1,
        onCreate: (db, version) {
      db.execute('''
        CREATE TABLE journal(
          id TEXT PRIMARY KEY,
          timestamp TEXT NOT NULL,
          from_account TEXT NOT NULL,
          to_account TEXT NOT NULL,
          amount REAL NOT NULL,
          signature TEXT NOT NULL
        )
      ''');
    });
  }

  Future<void> addTransaction({
    required String id,
    required String fromAccount,
    required String toAccount,
    required double amount,
    required String signature,
  }) async {
    final db = await this.db;
    await db.insert('journal', {
      'id': id,
      'timestamp': DateTime.now().toIso8601String(),
      'from_account': fromAccount,
      'to_account': toAccount,
      'amount': amount,
      'signature': signature,
    });
  }

  Future<double> getBalance(String accountId) async {
    final db = await this.db;
    final sent = await db.rawQuery('''
      SELECT SUM(amount) as total FROM journal WHERE from_account = ?
    ''', [accountId]);
    final received = await db.rawQuery('''
      SELECT SUM(amount) as total FROM journal WHERE to_account = ?
    ''', [accountId]);

    final sentTotal = sent[0]['total'] ?? 0.0;
    final receivedTotal = received[0]['total'] ?? 0.0;
    return receivedTotal - sentTotal;
  }
}