import 'package:flutter/material.dart';
import 'package:true_ledger_community/services/account_service.dart';
import 'package:true_ledger_community/screens/home_screen.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TrueLedgerApp());
}

class TrueLedgerApp extends StatelessWidget {
  const TrueLedgerApp({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'True Ledger Community',
      theme: ThemeData(primarySwatch: Colors.green),
      home: const InitializationScreen(),
    );
  }
}

class InitializationScreen extends StatefulWidget {
  const InitializationScreen({Key? key}) : super(key: key);

  @override
  State<InitializationScreen> createState() => _InitializationScreenState();
}

class _InitializationScreenState extends State<InitializationScreen> {
  @override
  Widget build(BuildContext context) {
    return FutureBuilder<Map<String, String>>(
      future: AccountService().initialize(),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.done) {
          final data = snapshot.data!;
          return HomeScreen(
            accountId: data['accountId']!,
            publicKey: data['publicKey']!,
            privateKey: data['privateKey']!,
          );
        }
        return const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        );
      },
    );
  }
}