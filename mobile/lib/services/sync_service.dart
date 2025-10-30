import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:true_ledger_community/models/transaction.dart';
import 'package:true_ledger_community/services/local_journal.dart';

class SyncService {
  static const String _BRANCH_URL = 'http://192.168.4.1:3000/sync';
  final LocalJournal _journal = LocalJournal();

  Future<bool> isBranchAvailable() async {
    try {
      final response = await http.get(Uri.parse('$_BRANCH_URL/health'));
      return response.statusCode == 200;
    } catch (_) {
      return false;
    }
  }

  Future<void> sync() async {
    if (!await isBranchAvailable()) return;

    final pending = await _journal.getPendingTransactions();
    if (pending.isEmpty) return;

    // Convert to payload format expected by branch server
    final transactions = pending.map((tx) => ({
      'payload': jsonEncode({
        'from': tx.fromAccount,
        'to': tx.toAccount,
        'amount': tx.amount,
        'timestamp': tx.timestamp,
      }),
      'signature': tx.signature,
      'sender_pubkey': tx.senderPubKey,
    })).toList();

    final body = jsonEncode({
      'deviceId': 'user_device_123', // TODO: use real device ID
      'transactions': transactions,
    });

    try {
      final response = await http.post(
        Uri.parse(_BRANCH_URL),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        // Mark all as synced
        for (final tx in pending) {
          await _journal.markAsSynced(tx.id);
        }
        print('✅ Synced ${pending.length} transactions');
      }
    } catch (e) {
      print('❌ Sync error: $e');
    }
  }
}