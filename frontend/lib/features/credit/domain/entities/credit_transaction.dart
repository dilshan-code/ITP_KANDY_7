// The CreditTransaction entity represents a single log entry for a customer's credit or payment history.
class CreditTransaction {
  final String id;
  final String customerId;
  final String type; // 'credit' or 'payment'
  final String title;
  final double amount;
  final String date;
  final String createdAt;

  CreditTransaction({
    required this.id,
    this.customerId = '',
    this.type = 'credit', // 'credit' (customer owes more) or 'payment' (customer paid back)
    this.title = '',
    this.amount = 0,
    this.date = '',
    this.createdAt = '',
  });

  factory CreditTransaction.fromJson(Map<String, dynamic> json) {
    return CreditTransaction(
      id: json['id'] ?? '',
      customerId: json['customerId'] ?? '',
      type: json['type'] ?? 'credit',
      title: json['title'] ?? '',
      amount: (json['amount'] ?? 0).toDouble(),
      date: json['date'] ?? '',
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'customerId': customerId,
      'type': type,
      'title': title,
      'amount': amount,
    };
  }
}
