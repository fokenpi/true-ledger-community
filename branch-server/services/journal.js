const sqlite3 = require('sqlite3').verbose();
const path = require('path');

class LocalJournal {
  constructor() {
    this.dbPath = path.join(__dirname, '..', 'data', 'synced.db');
    this.db = new sqlite3.Database(this.dbPath, (err) => {
      if (err) throw err;
      this.db.run(`CREATE TABLE IF NOT EXISTS transactions (
        id TEXT PRIMARY KEY,
        payload TEXT NOT NULL,
        signature TEXT NOT NULL,
        sender_pubkey TEXT NOT NULL,
        status TEXT DEFAULT 'pending',
        timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
      )`);
    });
  }

  saveTransaction(tx) {
    return new Promise((resolve, reject) => {
      this.db.run(
        `INSERT OR IGNORE INTO transactions (id, payload, signature, sender_pubkey) VALUES (?, ?, ?, ?)`,
        [tx.id, tx.payload, tx.signature, tx.sender_pubkey],
        function(err) {
          if (err) reject(err);
          else resolve(this.lastID);
        }
      );
    });
  }

  getPendingTransactions() {
    return new Promise((resolve, reject) => {
      this.db.all(
        `SELECT * FROM transactions WHERE status = 'pending' ORDER BY timestamp ASC`,
        (err, rows) => {
          if (err) reject(err);
          else resolve(rows);
        }
      );
    });
  }

  markAsUploaded(ids) {
    return new Promise((resolve, reject) => {
      const placeholders = ids.map(() => '?').join(',');
      this.db.run(
        `UPDATE transactions SET status = 'uploaded' WHERE id IN (${placeholders})`,
        ids,
        (err) => {
          if (err) reject(err);
          else resolve();
        }
      );
    });
  }
}

module.exports = LocalJournal;