import 'package:flutter/material.dart';
import 'package:true_ledger_community/services/local_journal.dart';
import 'package:true_ledger_community/screens/transfer_screen.dart';

class HomeScreen extends StatefulWidget {
  final String accountId;
  final String publicKey;
  final String privateKey;

  const HomeScreen({
    Key? key,
    required this.accountId,
    required this.publicKey,
    required this.privateKey,
  }) : super(key: key);

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  double _balance = 0.0;
  final LocalJournal _journal = LocalJournal();

  @override
  void initState() {
    super.initState();
    _loadBalance();
  }

  Future<void> _loadBalance() async {
    final balance = await _journal.getBalance(widget.accountId);
    if (mounted) {
      setState(() => _balance = balance);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('True Ledger Community')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Text(
              'Your Balance',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            Text(
              '\$${_balance.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 32, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 40),
            ElevatedButton(
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => TransferScreen(
                      accountId: widget.accountId,
                      publicKey: widget.publicKey,
                      privateKey: widget.privateKey,
                    ),
                  ),
                );
              },
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 32, vertical: 12),
                child: Text('Send Payment', style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
@override
void initState() {
  super.initState();
  _loadBalance();
  _startSyncWatcher();
}

void _startSyncWatcher() {
  // Check every 30 seconds
  Timer.periodic(const Duration(seconds: 30), (timer) async {
    if (await SyncService().isBranchAvailable()) {
      await SyncService().sync();
      _loadBalance(); // refresh balance
    }
  });
}