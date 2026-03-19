// The Customer entity represents a person or business who shops at the store.
// It tracks their profile and any outstanding debt (credit).
class Customer {
  final String id;
  final String name;
  final String phone;
  final String imageUrl;
  final double totalOutstanding;
  final double creditLimit;
  final String status;
  final String lastPurchase;
  final String createdAt;

  Customer({
    required this.id,
    required this.name,
    this.phone = '',
    this.imageUrl = '',
    this.totalOutstanding = 0, // The current amount of money this customer owes the shop
    this.creditLimit = 5000, // The maximum debt this customer is allowed to incur
    this.status = 'active',
    this.lastPurchase = '',
    this.createdAt = '',
  });

  factory Customer.fromJson(Map<String, dynamic> json) {
    return Customer(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      phone: json['phone'] ?? '',
      imageUrl: json['imageUrl'] ?? '',
      totalOutstanding:
          double.tryParse(json['totalOutstanding']?.toString() ?? '0') ?? 0.0,
      creditLimit:
          double.tryParse(json['creditLimit']?.toString() ?? '0') ?? 0.0,
      status: json['status'] ?? 'active',
      lastPurchase: json['lastPurchase'] ?? '',
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'phone': phone, 'creditLimit': creditLimit};
  }
}
