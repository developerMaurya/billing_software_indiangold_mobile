class SaleModel {
  String? id;
  String customerId;
  String customerName;
  String customerMobile;
  List<SaleItem> items;
  double subtotal;
  double discountPercent;
  double gstPercent;
  bool isInclusiveGst;
  double gstAmount;
  double totalAmount;
  DateTime saleDate;
  String? billNumber;

  SaleModel({
    this.id,
    required this.customerId,
    required this.customerName,
    required this.customerMobile,
    required this.items,
    required this.subtotal,
    required this.discountPercent,
    required this.gstPercent,
    required this.isInclusiveGst,
    required this.gstAmount,
    required this.totalAmount,
    required this.saleDate,
    this.billNumber,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'customerId': customerId,
      'customerName': customerName,
      'customerMobile': customerMobile,
      'items': items.map((item) => item.toMap()).toList(),
      'subtotal': subtotal,
      'discountPercent': discountPercent,
      'gstPercent': gstPercent,
      'isInclusiveGst': isInclusiveGst,
      'gstAmount': gstAmount,
      'totalAmount': totalAmount,
      'saleDate': saleDate.millisecondsSinceEpoch,
      'billNumber': billNumber,
    };
  }

  factory SaleModel.fromMap(Map<String, dynamic> map, String docId) {
    return SaleModel(
      id: docId,
      customerId: map['customerId'] ?? '',
      customerName: map['customerName'] ?? '',
      customerMobile: map['customerMobile'] ?? '',
      items:
          (map['items'] as List<dynamic>?)
              ?.map((item) => SaleItem.fromMap(item))
              .toList() ??
          [],
      subtotal: (map['subtotal'] ?? 0.0).toDouble(),
      discountPercent: (map['discountPercent'] ?? 0.0).toDouble(),
      gstPercent: (map['gstPercent'] ?? 5.0).toDouble(),
      isInclusiveGst: map['isInclusiveGst'] ?? false,
      gstAmount: (map['gstAmount'] ?? 0.0).toDouble(),
      totalAmount: (map['totalAmount'] ?? 0.0).toDouble(),
      saleDate: map['saleDate'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['saleDate'])
          : DateTime.now(),
      billNumber: map['billNumber'],
    );
  }
}

class SaleItem {
  String productId;
  String productName;
  String hsnCode;
  int quantity;
  double mrp;
  double rate;
  double amount;

  SaleItem({
    required this.productId,
    required this.productName,
    required this.hsnCode,
    required this.quantity,
    required this.mrp,
    required this.rate,
    required this.amount,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'hsnCode': hsnCode,
      'quantity': quantity,
      'mrp': mrp,
      'rate': rate,
      'amount': amount,
    };
  }

  factory SaleItem.fromMap(Map<String, dynamic> map) {
    return SaleItem(
      productId: map['productId'] ?? '',
      productName: map['productName'] ?? '',
      hsnCode: map['hsnCode'] ?? '',
      quantity: (map['quantity'] ?? 0).toInt(),
      mrp: (map['mrp'] ?? 0.0).toDouble(),
      rate: (map['rate'] ?? 0.0).toDouble(),
      amount: (map['amount'] ?? 0.0).toDouble(),
    );
  }
}
