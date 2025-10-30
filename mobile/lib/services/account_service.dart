import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:true_ledger_community/services/crypto_service.dart';

class AccountService {
  static const String _KEY_ACCOUNT_ID = 'account_id';
  static const String _KEY_PUBLIC_KEY = 'public_key';
  static const String _KEY_PRIVATE_KEY = 'private_key';

  Future<bool> isInitialized() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.containsKey(_KEY_ACCOUNT_ID);
  }

  Future<Map<String, String>> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    if (await isInitialized()) {
      return {
        'accountId': prefs.getString(_KEY_ACCOUNT_ID)!,
        'publicKey': prefs.getString(_KEY_PUBLIC_KEY)!,
        'privateKey': prefs.getString(_KEY_PRIVATE_KEY)!,
      };
    }

    // Generate new identity
    CryptoService.init();
    final keys = CryptoService.generateKeyPairSync();
    final accountId = 'acct_${DateTime.now().millisecondsSinceEpoch}';

    await prefs.setString(_KEY_ACCOUNT_ID, accountId);
    await prefs.setString(_KEY_PUBLIC_KEY, keys['publicKey']!);
    await prefs.setString(_KEY_PRIVATE_KEY, keys['privateKey']!);

    return {
      'accountId': accountId,
      'publicKey': keys['publicKey']!,
      'privateKey': keys['privateKey']!,
    };
  }
}