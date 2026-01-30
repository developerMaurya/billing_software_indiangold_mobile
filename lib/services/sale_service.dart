import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/sale_model.dart';
import '../models/product_model.dart';
import 'product_service.dart';

class SaleService {
  final CollectionReference _salesCollection = FirebaseFirestore.instance
      .collection('sales');
  final ProductService _productService = ProductService();

  Future<String> createSale(SaleModel sale) async {
    try {
      // Generate bill number
      final billNumber = await _generateBillNumber();
      sale.billNumber = billNumber;

      final docRef = await _salesCollection.add(sale.toMap());

      // Update inventory
      await _updateInventory(sale.items);

      return docRef.id;
    } catch (e) {
      throw Exception('Failed to create sale: $e');
    }
  }

  Future<String> _generateBillNumber() async {
    final now = DateTime.now();
    final dateStr =
        '${now.year}${now.month.toString().padLeft(2, '0')}${now.day.toString().padLeft(2, '0')}';

    final query = await _salesCollection
        .where('billNumber', isGreaterThanOrEqualTo: 'BILL-$dateStr')
        .where('billNumber', isLessThan: 'BILL-${dateStr}z')
        .orderBy('billNumber', descending: true)
        .limit(1)
        .get();

    int nextNumber = 1;
    if (query.docs.isNotEmpty) {
      final lastBill = query.docs.first['billNumber'] as String;
      final numberPart = lastBill.split('-').last;
      nextNumber = int.tryParse(numberPart) ?? 0 + 1;
    }

    return 'BILL-$dateStr${nextNumber.toString().padLeft(4, '0')}';
  }

  Future<void> _updateInventory(List<SaleItem> items) async {
    for (final item in items) {
      // Get current product
      final productQuery = await FirebaseFirestore.instance
          .collection('products')
          .where('name', isEqualTo: item.productName)
          .limit(1)
          .get();

      if (productQuery.docs.isNotEmpty) {
        final productDoc = productQuery.docs.first;
        final currentQuantity = productDoc['quantity'] as int;
        final newQuantity = currentQuantity - item.quantity;

        await productDoc.reference.update({'quantity': newQuantity});
      }
    }
  }

  Stream<List<SaleModel>> getSales() {
    return _salesCollection
        .orderBy('saleDate', descending: true)
        .snapshots()
        .map((snapshot) {
          return snapshot.docs.map((doc) {
            return SaleModel.fromMap(
              doc.data() as Map<String, dynamic>,
              doc.id,
            );
          }).toList();
        });
  }
}
