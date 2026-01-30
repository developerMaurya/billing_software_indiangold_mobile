class ProductModel {
  String? id;
  String name;
  String description;
  String hsnCode;
  double mrp;
  double buyRate;
  double givenRate;
  int quantity;
  String category;
  String? productType; // New: Bottle, Capsule, Syrup, etc.
  String? unitSize; // New: 100ml, 10 strips, etc.
  String? imageUrl;
  DateTime? createdAt;

  ProductModel({
    this.id,
    required this.name,
    required this.description,
    required this.hsnCode,
    required this.mrp,
    required this.buyRate,
    required this.givenRate,
    required this.quantity,
    required this.category,
    this.productType,
    this.unitSize,
    this.imageUrl,
    this.createdAt,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'description': description,
      'hsnCode': hsnCode,
      'mrp': mrp,
      'buyRate': buyRate,
      'givenRate': givenRate,
      'quantity': quantity,
      'category': category,
      'productType': productType,
      'unitSize': unitSize,
      'imageUrl': imageUrl,
      'createdAt': createdAt?.millisecondsSinceEpoch,
    };
  }

  factory ProductModel.fromMap(Map<String, dynamic> map, String docId) {
    return ProductModel(
      id: docId,
      name: map['name'] ?? '',
      description: map['description'] ?? '',
      hsnCode: map['hsnCode'] ?? '',
      mrp: (map['mrp'] ?? 0.0).toDouble(),
      buyRate: (map['buyRate'] ?? 0.0).toDouble(),
      givenRate: (map['givenRate'] ?? map['price'] ?? 0.0).toDouble(),
      quantity: (map['quantity'] ?? map['stock'] ?? 0).toInt(),
      category: map['category'] ?? '',
      productType: map['productType'],
      unitSize: map['unitSize'],
      imageUrl: map['imageUrl'],
      createdAt: map['createdAt'] != null
          ? DateTime.fromMillisecondsSinceEpoch(map['createdAt'])
          : null,
    );
  }

  ProductModel copyWith({
    String? id,
    String? name,
    String? description,
    String? hsnCode,
    double? mrp,
    double? buyRate,
    double? givenRate,
    int? quantity,
    String? category,
    String? productType,
    String? unitSize,
    String? imageUrl,
    DateTime? createdAt,
  }) {
    return ProductModel(
      id: id ?? this.id,
      name: name ?? this.name,
      description: description ?? this.description,
      hsnCode: hsnCode ?? this.hsnCode,
      mrp: mrp ?? this.mrp,
      buyRate: buyRate ?? this.buyRate,
      givenRate: givenRate ?? this.givenRate,
      quantity: quantity ?? this.quantity,
      category: category ?? this.category,
      productType: productType ?? this.productType,
      unitSize: unitSize ?? this.unitSize,
      imageUrl: imageUrl ?? this.imageUrl,
      createdAt: createdAt ?? this.createdAt,
    );
  }
}
