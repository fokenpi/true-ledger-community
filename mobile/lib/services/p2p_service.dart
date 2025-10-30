import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:nearby_connections/nearby_connections.dart';
import 'package:true_ledger_community/services/crypto_service.dart';
import 'package:true_ledger_community/services/local_journal.dart';

class P2PService {
  final String myAccountId;
  final String myPublicKey;
  final String myPrivateKey;
  final LocalJournal journal;

  NearbyConnections? _nearby;
  bool _isAdvertising = false;

  P2PService({
    required this.myAccountId,
    required this.myPublicKey,
    required this.myPrivateKey,
    required this.journal,
  });

  Future<void> init() async {
    CryptoService.init();
    _nearby = NearbyConnections(
      serviceId: 'true.ledger.community',
      onConnectionInitiated: _onConnectionInitiated,
      onConnectionResult: _onConnectionResult,
      onDisconnected: _onDisconnected,
      onPayloadReceived: _onPayloadReceived,
    );
  }

  // Start advertising this device as a peer
  Future<void> startAdvertising() async {
    if (_isAdvertising) return;
    await _nearby?.startAdvertising(
      myAccountId,
      strategy: Strategy.P2P_CLUSTER,
    );
    _isAdvertising = true;
  }

  // Discover nearby peers
  Future<void> startDiscovery(Function(String endpointId, String deviceId) onFound) async {
    await _nearby?.startDiscovery(
      'TrueLedger',
      strategy: Strategy.P2P_CLUSTER,
      onEndpointFound: (id, name, _) => onFound(id, name),
      onEndpointLost: (_) {},
    );
  }

  // Send a signed transaction to a peer
  Future<void> sendTransaction({
    required String toAccountId,
    required double amount,
    required String recipientEndpointId,
  }) async {
    final payload = jsonEncode({
      'from': myAccountId,
      'to': toAccountId,
      'amount': amount,
      'timestamp': DateTime.now().toIso8601String(),
    });

    final signature = CryptoService.sign(payload, myPrivateKey);
    final message = jsonEncode({
      'type': 'transaction',
      'payload': payload,
      'signature': signature,
      'sender_pubkey': myPublicKey,
    });

    await _nearby?.sendPayload(
      recipientEndpointId,
      Payload.bytes(utf8.encode(message)),
    );
  }

  // Handle incoming payload
  void _onPayloadReceived(String _, Payload payload) async {
    if (payload.type != PayloadType.BYTES) return;

    final data = utf8.decode(payload.bytes!);
    final msg = jsonDecode(data);

    if (msg['type'] == 'transaction') {
      final isValid = CryptoService.verify(
        msg['payload'],
        msg['signature'],
        msg['sender_pubkey'],
      );

      if (isValid) {
        final tx = jsonDecode(msg['payload']);
        await journal.addTransaction(
          id: DateTime.now().millisecondsSinceEpoch.toString(),
          fromAccount: tx['from'],
          toAccount: tx['to'],
          amount: tx['amount'],
          signature: msg['signature'],
        );
      }
    }
  }

  void _onConnectionInitiated(String _, ConnectionInfo info) {
    _nearby?.acceptConnection(info.endpointId, (_, __) {});
  }

  void _onConnectionResult(String _, ConnectionResult result) {}
  void _onDisconnected(String _) {}

  Future<void> dispose() async {
    if (_isAdvertising) {
      await _nearby?.stopAdvertising();
      _isAdvertising = false;
    }
    await _nearby?.stopDiscovery();
    await _nearby?.dispose();
  }
}