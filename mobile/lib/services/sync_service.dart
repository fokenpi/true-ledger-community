import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:true_ledger_community/services/local_journal.dart';

class SyncService {
  static const String _BRANCH_SERVER_URL = 'http://192.168.4.1:3000/sync';
  final LocalJournal _journal = LocalJournal();

  // Check if connected to branch Wi-Fi (simplified)
  Future<bool> isConnectedToBranch() async {
    try {
      final response = await http.get(Uri.parse('$_BRANCH_SERVER_URL/health'));
      return response.statusCode == 200;
    } catch (e) {
      return false;
    }
  }

  // Upload pending transactions to branch server
  Future<void> syncPendingTransactions(String deviceId) async {
    // TODO: In a real app, fetch pending transactions from local journal
    // For now, simulate with a hardcoded list
    final pendingTransactions = [
      {
        'payload': '{"from":"acct_123","to":"acct_456","amount":50.0,"timestamp":"2025-10-31T10:00:00Z"}',
        'signature': 'MEUCIQ...', // from local journal
        'sender_pubkey': '-----BEGIN PUBLIC KEY-----...'
      }
    ];

    final body = jsonEncode({
      'deviceId': deviceId,
      'transactions': pendingTransactions,
    });

    try {
      final response = await http.post(
        Uri.parse(_BRANCH_SERVER_URL),
        headers: {'Content-Type': 'application/json'},
        body: body,
      );

      if (response.statusCode == 200) {
        // TODO: Mark transactions as synced in local journal
        print('✅ Sync successful');
      } else