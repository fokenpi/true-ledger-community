class Transaction {
  final String id;
  final String fromAccount;
  final String toAccount;
  final double amount;
  final String timestamp;
  final String signature;
  final String senderPubKey;
  final String status; // 'pending' | 'synced'

  Transaction({
    required this.id,
    required this.fromAccount,
    required this.toAccount,
    required this.amount,
    required this.timestamp,
    required this.signature,
    required this.senderPubKey,
    this.status = 'pending',
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'from_account': fromAccount,
        'to_account': toAccount,
        'amount': amount,
        'timestamp': timestamp,
        'signature': signature,
        'sender_pubkey': senderPubKey,
        'status': status,
      };

  factory Transaction.fromJson(Map<String, dynamic> json) => Transaction(
        id: json['id'],
        fromAccount: json['from_account'],
        toAccount: json['to_account'],
        amount: json['amount'].toDouble(),
        timestamp: json['timestamp'],
        signature: json['signature'],
        senderPubKey: json['sender_pubkey'],
        status: json['status'] ?? 'pending',
      );
}