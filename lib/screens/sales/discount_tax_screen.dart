import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:printing/printing.dart';
import '../../models/customer_model.dart';
import '../../models/sale_model.dart';
import '../../services/sale_service.dart';
import '../../services/pdf_service.dart';
import 'bill_preview_screen.dart';

class DiscountTaxScreen extends StatefulWidget {
  final CustomerModel customer;
  final List<Map<String, dynamic>> selectedProducts;
  final Map<String, dynamic>? companyData;

  const DiscountTaxScreen({
    super.key,
    required this.customer,
    required this.selectedProducts,
    this.companyData,
  });

  @override
  State<DiscountTaxScreen> createState() => _DiscountTaxScreenState();
}

class _DiscountTaxScreenState extends State<DiscountTaxScreen> {
  double discountPercent = 0.0;
  double gstPercent = 5.0;
  bool isInclusiveGst = false;
  bool isLoading = false;

  double get subtotal => widget.selectedProducts.fold(
    0.0,
    (sum, item) => sum + (item['quantity'] * item['price']),
  );

  double get discountAmount => subtotal * (discountPercent / 100);

  double get taxableAmount => subtotal - discountAmount;

  double get gstAmount {
    if (isInclusiveGst) {
      return taxableAmount - (taxableAmount / (1 + gstPercent / 100));
    } else {
      return taxableAmount * (gstPercent / 100);
    }
  }

  double get totalAmount {
    if (isInclusiveGst) {
      return taxableAmount;
    } else {
      return taxableAmount + gstAmount;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        title: const Text(
          'Discount & Tax Settings',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
        elevation: 0,
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Customer Details
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Customer Details',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text('Name: ${widget.customer.name}'),
                    Text('Mobile: ${widget.customer.mobile}'),
                    Text('Address: ${widget.customer.address}'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Products Summary
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Products Summary',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Total Items: ${widget.selectedProducts.fold(0, (sum, item) => sum + item['quantity'] as int)}',
                    ),
                    Text('Subtotal: ₹${subtotal.toStringAsFixed(2)}'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Discount Settings
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Discount Settings',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('Discount (%):'),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            initialValue: discountPercent.toString(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: '0.0',
                            ),
                            onChanged: (value) {
                              setState(() {
                                discountPercent = double.tryParse(value) ?? 0.0;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Discount Amount: ₹${discountAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        color: Colors.red.shade700,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Tax Settings
            Card(
              elevation: 4,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tax Settings (GST)',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        const Text('GST Type:'),
                        const SizedBox(width: 16),
                        DropdownButton<bool>(
                          value: isInclusiveGst,
                          items: const [
                            DropdownMenuItem(
                              value: false,
                              child: Text('Exclusive'),
                            ),
                            DropdownMenuItem(
                              value: true,
                              child: Text('Inclusive'),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() => isInclusiveGst = value!);
                          },
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        const Text('GST (%):'),
                        const SizedBox(width: 16),
                        Expanded(
                          child: TextFormField(
                            initialValue: gstPercent.toString(),
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: '5.0',
                            ),
                            onChanged: (value) {
                              setState(() {
                                gstPercent = double.tryParse(value) ?? 5.0;
                              });
                            },
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Taxable Amount: ₹${taxableAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      'GST Amount: ₹${gstAmount.toStringAsFixed(2)}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const Divider(),
                    Text(
                      'Total Amount: ₹${totalAmount.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.green.shade800,
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 32),

            // Actions
            Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      side: const BorderSide(color: Colors.red),
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Back'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: _viewBill,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.blue.shade700,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('View Bill'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _generateBill,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Text('Generate Bill'),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _viewBill() {
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => BillPreviewScreen(
          customer: widget.customer,
          selectedProducts: widget.selectedProducts,
          companyData: widget.companyData,
          discountPercent: discountPercent,
          gstPercent: gstPercent,
          isInclusiveGst: isInclusiveGst,
        ),
      ),
    );
  }

  Future<void> _generateBill() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Generate Bill'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('Total Amount: ₹${totalAmount.toStringAsFixed(2)}'),
            const SizedBox(height: 8),
            const Text('This will save the sale and generate a PDF bill.'),
            const SizedBox(height: 8),
            const Text('Product quantities will be reduced from inventory.'),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text('Generate'),
          ),
        ],
      ),
    );

    if (confirm != true) return;

    setState(() => isLoading = true);

    try {
      // Create sale items
      final saleItems = widget.selectedProducts.map((item) {
        final product = item['product'];
        final quantity = item['quantity'] as int;
        final price = item['price'] as double;
        return SaleItem(
          productId: product.id ?? '',
          productName: product.name,
          hsnCode: product.hsnCode,
          quantity: quantity,
          mrp: product.mrp,
          rate: price,
          amount: quantity * price,
        );
      }).toList();

      // Create sale
      final sale = SaleModel(
        customerId: widget.customer.id ?? '',
        customerName: widget.customer.name,
        customerMobile: widget.customer.mobile,
        items: saleItems,
        subtotal: subtotal,
        discountPercent: discountPercent,
        gstPercent: gstPercent,
        isInclusiveGst: isInclusiveGst,
        gstAmount: gstAmount,
        totalAmount: totalAmount,
        saleDate: DateTime.now(),
        billNumber:
            '', // Will be generated by backend if not handled there, or generate simple one here
      );

      final saleService = SaleService();
      // The service should ideally return the created sale with ID and stuff, but we'll use the ID returned
      // ignore: unused_local_variable
      final saleId = await saleService.createSale(sale);

      // Update product quantities in inventory
      await _updateProductQuantities();

      // Generate PDF
      final pdfService = PdfService();
      final pdf = await pdfService.generateBillPdf(
        sale: sale,
        customer: widget.customer,
        companyData: widget.companyData,
      );

      // Show PDF preview / Print
      await Printing.layoutPdf(
        onLayout: (PdfPageFormat format) async => pdf.save(),
      );

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Bill generated successfully!'),
            backgroundColor: Colors.green,
          ),
        );
        // Close all screens and go back to main screen
        Navigator.of(context).popUntil((route) => route.isFirst);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error generating bill: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  Future<void> _updateProductQuantities() async {
    try {
      for (final item in widget.selectedProducts) {
        final product = item['product'];
        final quantitySold = item['quantity'] as int;

        if (product.id != null) {
          // Get current product data
          final productDoc = await FirebaseFirestore.instance
              .collection('products')
              .doc(product.id)
              .get();

          if (productDoc.exists) {
            final currentQuantity = productDoc.data()?['quantity'] ?? 0;
            final newQuantity = currentQuantity - quantitySold;

            // Update product quantity
            await FirebaseFirestore.instance
                .collection('products')
                .doc(product.id)
                .update({'quantity': newQuantity});
          }
        }
      }
    } catch (e) {
      debugPrint('Error updating product quantities: $e');
    }
  }
}
