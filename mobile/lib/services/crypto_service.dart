import 'dart:convert';
import 'dart:typed_data';
import 'package:pointycastle/export.dart';
import 'package:pointycastle/digests/sha256.dart';

class CryptoService {
  // Initialize PointyCastle (required for web & mobile)
  static void init() {
    if (!registry.isInitialized) registry.init();
  }

  // Generate keypair (run in compute() to avoid UI freeze)
  static Map<String, String> generateKeyPairSync() {
    init();
    final ecParams = ECCurve_secp256k1();
    final random = FortunaRandom();
    random.seed(KeyParameter(Platform.instance.platformEntropySource().getBytes(32)));

    final keyGen = ECKeyGenerator();
    keyGen.init(ParametersWithRandom(ECKeyGeneratorParameters(ecParams), random));
    final keyPair = keyGen.generateKeyPair();

    final priv = (keyPair.privateKey as ECPrivateKey).d;
    final pub = (keyPair.publicKey as ECPublicKey).Q.getEncoded(false);

    return {
      'privateKey': base64Encode(priv!.bytes),
      'publicKey': base64Encode(pub),
    };
  }

  // Sign a JSON-serializable payload
  static String sign(String payload, String base64PrivateKey) {
    init();
    final ecParams = ECCurve_secp256k1();
    final digest = SHA256Digest().process(utf8.encode(payload));

    final privBytes = base64Decode(base64PrivateKey);
    final privBigInt = _bytesToBigInt(privBytes);
    final privateKey = ECPrivateKey(privBigInt, ecParams);

    final signer = ECDSASigner(null, HMac(SHA256Digest(), 32));
    signer.init(true, PrivateKeyParameter(privateKey));
    final sig = signer.generateSignature(digest);

    return _encodeSignature(sig.r!, sig.s!);
  }

  // Verify signature
  static bool verify(String payload, String base64Signature, String base64PublicKey) {
    init();
    final ecParams = ECCurve_secp256k1();
    final digest = SHA256Digest().process(utf8.encode(payload));

    final pubBytes = base64Decode(base64PublicKey);
    final pubKey = ECPublicKey(ecParams.curve.decodePoint(pubBytes), ecParams);

    final sigBytes = base64Decode(base64Signature);
    final half = sigBytes.length ~/ 2;
    final r = _bytesToBigInt(sigBytes.sublist(0, half));
    final s = _bytesToBigInt(sigBytes.sublist(half));
    final signature = ECSignature(r, s);

    final verifier = ECDSASigner(null, HMac(SHA256Digest(), 32));
    verifier.init(false, PublicKeyParameter(pubKey));
    return verifier.verifySignature(digest, signature);
  }

  // Helpers
  static BigInt _bytesToBigInt(Uint8List bytes) {
    return BigInt.parse(bytes.map((b) => b.toRadixString(16).padLeft(2, '0')).join(), radix: 16);
  }

  static String _encodeSignature(BigInt r, BigInt s) {
    final rBytes = r.toRadixString(16).padLeft(64, '0');
    final sBytes = s.toRadixString(16).padLeft(64, '0');
    final all = Uint8List.fromList(
      List<int>.generate(64, (i) => int.parse(rBytes.substring(i * 2, i * 2 + 2), radix: 16)) +
      List<int>.generate(64, (i) => int.parse(sBytes.substring(i * 2, i * 2 + 2), radix: 16))
    );
    return base64Encode(all);
  }
}