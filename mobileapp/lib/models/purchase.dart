class Purchase {
  String supplierId;
  String supplierName;
  String phone;
  String date;
  int quantity;
  double unitPrice;
  double total;
  String status; // Paid or Pending
  String? billPath;

  Purchase({
    required this.supplierId,
    required this.supplierName,
    required this.phone,
    required this.date,
    required this.quantity,
    required this.unitPrice,
    required this.total,
    this.status = "Pending",
    this.billPath,
  });
}
