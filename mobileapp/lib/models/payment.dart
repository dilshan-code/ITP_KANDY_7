class Payment {
  String supplierId;
  String supplierName;
  String date;
  int quantity;
  double amount;
  String status;

  Payment({
    required this.supplierId,
    required this.supplierName,
    required this.date,
    required this.quantity,
    required this.amount,
    required this.status,
  });
}
