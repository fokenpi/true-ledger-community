// True Ledger Community - Branch Sync Server
const express = require('express');
const app = express();
app.use(express.json());

app.post('/sync', (req, res) => {
  res.json({ success: true });
});

app.listen(3000, () => console.log('SetBranch server running'));