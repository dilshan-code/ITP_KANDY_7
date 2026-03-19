// The Owner entity represents a shop manager's account details in the Flutter app.
class Owner {
  final String id;
  final String name;
  final String shopName;
  final String phone;
  final String email;
  final String createdAt;

  Owner({
    required this.id,
    required this.name,
    this.shopName = '', // The name of the business they manage
    this.phone = '',
    required this.email,
    this.createdAt = '',
  });

  factory Owner.fromJson(Map<String, dynamic> json) {
    return Owner(
      id: json['id'] ?? '',
      name: json['name'] ?? '',
      shopName: json['shopName'] ?? '',
      phone: json['phone'] ?? '',
      email: json['email'] ?? '',
      createdAt: json['createdAt'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {'name': name, 'shopName': shopName, 'phone': phone, 'email': email};
  }
}
