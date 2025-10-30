// True Ledger Community - Branch Sync Server
const express = require('express');
const sqlite3 = require('sqlite3').verbose();
const { Storage } = require('@google-cloud/storage');
const crypto = require('crypto');
const cors = require('cors');
const path = require('path');

const app = express();
app.use(express.json());
app.use(cors());

// Initialize local SQLite database
const dbPath = path.join(__dirname, 'data', 'synced.db');
const db = new sqlite3.Database(dbPath, (err) => {
  if (err) throw err;
  db.run(`CREATE TABLE IF NOT EXISTS transactions (
    id TEXT PRIMARY KEY,
    payload TEXT NOT NULL,
    signature TEXT NOT NULL,
    sender_pubkey TEXT NOT NULL,
    timestamp DATETIME DEFAULT CURRENT_TIMESTAMP
  )`);
});

// GCS client (uses ADC or service account key)
const storage = new Storage();
const BUCKET_NAME = 'true-ledger-archive-' + process.env.GCLOUD_PROJECT;

// In-memory batch queue
let batch = [];
const BATCH_SIZE = 10;
const BATCH_TIMEOUT = 60000; // 1 minute
let batchTimer;

function resetBatchTimer() {
  clearTimeout(batchTimer);
  batchTimer = setTimeout(uploadBatch, BATCH_TIMEOUT);
}

async function uploadBatch() {
  if (batch.length === 0) return;

  const batchCopy = [...batch];
  batch = []; // reset

  try {
    // Sort by timestamp for deterministic order
    batchCopy.sort((a, b) => new Date(a.timestamp) - new Date(b.timestamp));
    
    // Create hash chain
    let prevHash = '0'.repeat(64);
    const chainedBatch = batchCopy.map(tx => {
      const hash = crypto.createHash('sha256')
        .update(JSON.stringify({ ...tx, prev_hash: prevHash }))
        .digest('hex');
      prevHash = hash;
      return { ...tx, hash, prev_hash: prevHash };
    });

    // Upload to GCS
    const fileName = `batch_${Date.now()}.json`;
    const file = storage.bucket(BUCKET_NAME).file(`batches/${fileName}`);
    await file.save(JSON.stringify(chainedBatch, null, 2), {
      contentType: 'application/json',
      resumable: false
    });

    console.log(`✅ Uploaded batch: ${fileName} (${chainedBatch.length} transactions)`);
  } catch (error) {
    console.error('❌ Failed to upload batch:', error);
    // Re-queue on failure
    batch.push(...batchCopy);
    resetBatchTimer();
  }
}

// Sync endpoint
app.post('/sync', async (req, res) => {
  const { deviceId, transactions } = req.body;

  if (!Array.isArray(transactions) || transactions.length === 0) {
    return res.status(400).json({ error: 'No transactions provided' });
  }

  // Validate and save each transaction
  for (const tx of transactions) {
    const { payload, signature, sender_pubkey } = tx;
    
    // Basic validation
    if (!payload || !signature || !sender_pubkey) {
      continue; // skip invalid
    }

    // TODO: Add cryptographic verification (requires secp256k1 in Node.js)

    // Save to local DB
    db.run(
      `INSERT OR IGNORE INTO transactions (id, payload, signature, sender_pubkey) VALUES (?, ?, ?, ?)`,
      [Date.now().toString() + Math.random().toString(36).slice(2, 10), payload, signature, sender_pubkey],
      function(err) {
        if (err) console.error('DB insert error:', err);
      }
    );

    // Add to batch
    batch.push({ payload, signature, sender_pubkey, timestamp: new Date().toISOString() });
  }

  // Trigger batch upload
  if (batch.length >= BATCH_SIZE) {
    clearTimeout(batchTimer);
    uploadBatch();
  } else {
    resetBatchTimer();
  }

  res.json({ success: true, accepted: transactions.length });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`SetBranch server running on http://0.0.0.0:${PORT}`);
  console.log(`GCS Bucket: ${BUCKET_NAME}`);
});