import 'dart:async';
import 'package:flutter/material.dart';
import 'package:true_ledger_community/services/p2p_service.dart';
import 'package:true_ledger_community/services/local_journal.dart';
import 'package:true_ledger_community/services/crypto_service.dart';

class TransferScreen extends StatefulWidget {
  final String accountId;
  final String publicKey;
  final String privateKey;

  const TransferScreen({
    Key? key,
    required this.accountId,
    required this.publicKey,
    required this.privateKey,
  }) : super(key: key);

  @override
  State<TransferScreen> createState() => _TransferScreenState();
}

class _TransferScreenState extends State<TransferScreen> {
  final LocalJournal _journal = LocalJournal();
  late P2PService _p2p;
  final List<Map<String, String>> _peers = [];
  String? _selectedPeer;
  final TextEditingController _amountController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initP2P();
  }

  Future<void> _initP2P() async {
    _p2p = P2PService(
      myAccountId: widget.accountId,
      myPublicKey: widget.publicKey,
      myPrivateKey: widget.privateKey,
      journal: _journal,
    );
    await _p2p.init();
    await _p2p.startAdvertising();

    // Discover peers
    await _p2p.startDiscovery((id, name) {
      if (!mounted) return;
      setState(() {
        if (!_peers.any((p) => p['id'] == id)) {
          _peers.add({'id': id, 'name': name});
        }
      });
    });

    // Auto-refresh every 10 seconds
    Timer.periodic(const Duration(seconds: 10), (_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _sendTransaction() async {
    if (_selectedPeer == null || _amountController.text.isEmpty) return;

    final amount = double.tryParse(_amountController.text);
    if (amount == null || amount <= 0) return;

    await _p2p.sendTransaction(
      toAccountId: _selectedPeer!,
      amount: amount,
      recipientEndpointId: _selectedPeer!,
    );

    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text('Transaction sent!')),
    );
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Send Payment')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            const Text('Nearby Users', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 10),
            ..._peers.map((peer) {
              return RadioListTile<String>(
                title: Text(peer['name']!),
                value: peer['id'],
                groupValue: _selectedPeer,
                onChanged: (value) {
                  setState(() => _selectedPeer = value);
                },
              );
            }),
            const SizedBox(height: 20),
            TextField(
              controller: _amountController,
              decoration: const InputDecoration(
                labelText: 'Amount',
                hintText: '0.00',
                border: OutlineInputBorder(),
              ),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 20),
            ElevatedButton(
              onPressed: _sendTransaction,
              child: const Text('Send'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  void dispose() {
    _amountController.dispose();
    _p2p.dispose();
    super.dispose();
  }
}