const express = require('express');
const cors = require('cors');
const LocalJournal = require('./services/journal');
const { verifySignature } = require('./services/validator');
const GCSUploader = require('./services/uploader');

const app = express();
app.use(express.json());
app.use(cors());

// Initialize services
const journal = new LocalJournal();
const uploader = new GCSUploader(`true-ledger-archive-${process.env.GCLOUD_PROJECT}`);

// Batch processing
let pendingBatch = [];
const BATCH_SIZE = 10;
const BATCH_TIMEOUT = 60000; // 1 minute
let batchTimer;

function resetBatchTimer() {
  clearTimeout(batchTimer);
  batchTimer = setTimeout(processBatch, BATCH_TIMEOUT);
}

async function processBatch() {
  if (pendingBatch.length === 0) return;

  const batch = [...pendingBatch];
  pendingBatch = [];

  try {
    const uploadedIds = await uploader.uploadBatch(batch);
    await journal.markAsUploaded(uploadedIds);
  } catch (error) {
    console.error('Batch upload failed:', error);
    pendingBatch.push(...batch); // retry
    resetBatchTimer();
  }
}

// Sync endpoint
app.post('/sync', async (req, res) => {
  const { deviceId, transactions } = req.body;

  if (!Array.isArray(transactions)) {
    return res.status(400).json({ error: 'Invalid transactions format' });
  }

  const accepted = [];
  for (const tx of transactions) {
    const { payload, signature, sender_pubkey } = tx;
    if (!payload || !signature || !sender_pubkey) continue;

    // Verify signature
    if (!verifySignature(payload, signature, sender_pubkey)) {
      console.warn('Invalid signature from', sender_pubkey);
      continue;
    }

    // Save to local journal
    const id = `${Date.now()}-${Math.random().toString(36).substr(2, 9)}`;
    await journal.saveTransaction({
      id,
      payload,
      signature,
      sender_pubkey,
      timestamp: new Date().toISOString()
    });

    pendingBatch.push({
      id,
      payload,
      signature,
      sender_pubkey,
      timestamp: new Date().toISOString()
    });

    accepted.push(id);
  }

  // Trigger batch processing
  if (pendingBatch.length >= BATCH_SIZE) {
    clearTimeout(batchTimer);
    processBatch();
  } else {
    resetBatchTimer();
  }

  res.json({ success: true, accepted: accepted.length });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, '0.0.0.0', () => {
  console.log(`SetBranch server running on http://0.0.0.0:${PORT}`);
});
// Add this to server.js
app.get('/health', (req, res) => {
  res.json({ status: 'ok', server: 'True Ledger Branch' });
});