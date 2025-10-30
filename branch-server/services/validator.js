// ECDSA verification using secp256k1 (same as Bitcoin)
const EC = require('elliptic').ec;
const sha256 = require('sha.js')('sha256');
const ec = new EC('secp256k1');

function verifySignature(payload, signature, publicKey) {
  try {
    // Hash the payload
    const hash = sha256.update(payload).digest();

    // Parse signature (assumes base64-encoded r+s)
    const sigBytes = Buffer.from(signature, 'base64');
    const half = sigBytes.length / 2;
    const r = sigBytes.slice(0, half).toString('hex');
    const s = sigBytes.slice(half).toString('hex');

    // Parse public key (assumes compressed or uncompressed format)
    const key = ec.keyFromPublic(publicKey, 'base64');

    // Verify
    return ec.verify(hash, { r, s }, key);
  } catch (err) {
    console.error('Verification error:', err.message);
    return false;
  }
}

module.exports = { verifySignature };