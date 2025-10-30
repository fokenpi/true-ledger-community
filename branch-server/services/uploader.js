const { Storage } = require('@google-cloud/storage');
const crypto = require('crypto');

class GCSUploader {
  constructor(bucketName) {
    this.storage = new Storage();
    this.bucketName = bucketName;
  }

  async uploadBatch(transactions) {
    if (transactions.length === 0) return;

    // Sort for deterministic order
    transactions.sort((a, b) => new Date(a.timestamp) - new Date(b.timestamp));

    // Build hash chain
    let prevHash = '0'.repeat(64);
    const chained = transactions.map(tx => {
      const content = JSON.stringify({ ...tx, prev_hash: prevHash });
      const hash = crypto.createHash('sha256').update(content).digest('hex');
      prevHash = hash;
      return { ...tx, hash, prev_hash: prevHash };
    });

    // Upload to GCS
    const fileName = `batches/batch_${Date.now()}.json`;
    const file = this.storage.bucket(this.bucketName).file(fileName);
    await file.save(JSON.stringify(chained, null, 2), {
      contentType: 'application/json',
      resumable: false
    });

    console.log(`✅ Uploaded batch: ${fileName} (${chained.length} transactions)`);
    return chained.map(t => t.id);
  }
}

module.exports = GCSUploader;