import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../../models/customer_model.dart';
import '../../models/sale_model.dart';
import '../../services/sale_service.dart';

class BillGenerationScreen extends StatefulWidget {
  final CustomerModel customer;
  final List<Map<String, dynamic>> selectedProducts;
  final Map<String, dynamic>? companyData;
  final double discountPercent;
  final double gstPercent;
  final bool isInclusiveGst;

  const BillGenerationScreen({
    super.key,
    required this.customer,
    required this.selectedProducts,
    this.companyData,
    this.discountPercent = 0.0,
    this.gstPercent = 5.0,
    this.isInclusiveGst = false,
  });

  @override
  State<BillGenerationScreen> createState() => _BillGenerationScreenState();
}

class _BillGenerationScreenState extends State<BillGenerationScreen> {
  bool isLoading = false;

  double get subtotal => widget.selectedProducts.fold(
    0.0,
    (sum, item) => sum + (item['quantity'] * item['price']),
  );

  double get discountAmount => subtotal * (widget.discountPercent / 100);

  double get taxableAmount => subtotal - discountAmount;

  double get gstAmount {
    if (widget.isInclusiveGst) {
      return taxableAmount - (taxableAmount / (1 + widget.gstPercent / 100));
    } else {
      return taxableAmount * (widget.gstPercent / 100);
    }
  }

  double get totalAmount {
    if (widget.isInclusiveGst) {
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
        title: const Text('Generate Bill'),
        backgroundColor: Colors.green.shade700,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Company Details
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      widget.companyData?['name'] ?? 'Company Name',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      widget.companyData?['address'] ?? '',
                      textAlign: TextAlign.center,
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    if (widget.companyData?['pinCode'] != null) ...[
                      Text('Pincode: ${widget.companyData!['pinCode']}'),
                    ],
                    Text(
                      'Phone: ${widget.companyData?['mobile'] ?? ''} | GST: ${widget.companyData?['gst'] ?? ''}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    const Text('State: Maharashtra | Country: India'),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Customer Details
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Bill To / ग्राहक विवरण',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'Name: ${widget.customer.name}',
                      style: const TextStyle(fontWeight: FontWeight.w500),
                    ),
                    Text(
                      'Mobile: ${widget.customer.mobile} | WhatsApp: ${widget.customer.whatsapp ?? widget.customer.mobile}',
                    ),
                    Text('Address: ${widget.customer.address}'),
                    if (widget.customer.pinCode != null) ...[
                      Text('Pincode: ${widget.customer.pinCode}'),
                    ],
                    Text(
                      'Status: ${widget.customer.status} | Country: ${widget.customer.country}',
                    ),
                    if (widget.customer.email != null) ...[
                      Text('Email: ${widget.customer.email}'),
                    ],
                    const Text(
                      'GST No: Not Applicable',
                      style: TextStyle(fontStyle: FontStyle.italic),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Products
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Products',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 8),
                    ...widget.selectedProducts.map((item) {
                      final product = item['product'] as dynamic;
                      final quantity = item['quantity'] as int;
                      final price = item['price'] as double;
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8),
                        child: Row(
                          children: [
                            Expanded(child: Text(product.name)),
                            Text('HSN: ${product.hsnCode}'),
                            const SizedBox(width: 8),
                            Text('Qty: $quantity'),
                            const SizedBox(width: 8),
                            Text('₹${price.toStringAsFixed(2)}'),
                            const SizedBox(width: 8),
                            Text('₹${(quantity * price).toStringAsFixed(2)}'),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),

            const SizedBox(height: 16),

            // Totals
            Card(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text('Subtotal:'),
                        Text('₹${subtotal.toStringAsFixed(2)}'),
                      ],
                    ),
                    if (widget.discountPercent > 0) ...[
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Discount (${widget.discountPercent}%):'),
                          Text('-₹${discountAmount.toStringAsFixed(2)}'),
                        ],
                      ),
                    ],
                    const SizedBox(height: 8),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'GST (${widget.gstPercent}% ${widget.isInclusiveGst ? 'Inc.' : 'Exc.'}):',
                        ),
                        Text('₹${gstAmount.toStringAsFixed(2)}'),
                      ],
                    ),
                    const Divider(),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        const Text(
                          'Total Amount:',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                        Text(
                          '₹${totalAmount.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ],
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
                    child: const Text('Cancel'),
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
                        ? const CircularProgressIndicator()
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

  Future<void> _generateBill() async {
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
        discountPercent: widget.discountPercent,
        gstPercent: widget.gstPercent,
        isInclusiveGst: widget.isInclusiveGst,
        gstAmount: gstAmount,
        totalAmount: totalAmount,
        saleDate: DateTime.now(),
      );

      final saleService = SaleService();
      final saleId = await saleService.createSale(sale);

      // Update product quantities in inventory
      await _updateProductQuantities();

      // Generate PDF
      final pdf = await _generatePdf(sale);

      // Show PDF preview
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
      // Don't throw error here as the sale is already created
    }
  }

  Future<pw.Document> _generatePdf(SaleModel sale) async {
    final pdf = pw.Document();

    pdf.addPage(
      pw.Page(
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              // Company Header
              pw.Text(
                widget.companyData?['name'] ?? 'Company Name',
                style: pw.TextStyle(
                  fontSize: 28,
                  fontWeight: pw.FontWeight.bold,
                ),
                textAlign: pw.TextAlign.center,
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                widget.companyData?['address'] ?? '',
                textAlign: pw.TextAlign.center,
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              if (widget.companyData?['pinCode'] != null) ...[
                pw.Text('Pincode: ${widget.companyData!['pinCode']}'),
              ],
              pw.Text(
                'Phone: ${widget.companyData?['mobile'] ?? ''} | GST: ${widget.companyData?['gst'] ?? ''}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text('State: Maharashtra | Country: India'),
              pw.SizedBox(height: 16),

              // Bill Info
              pw.Text('Bill No: ${sale.billNumber}'),
              pw.Text('Date: ${sale.saleDate.toString().split(' ')[0]}'),
              pw.SizedBox(height: 16),

              // Customer Details
              pw.Text(
                'Bill To / ग्राहक विवरण',
                style: pw.TextStyle(
                  fontSize: 16,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Name: ${sale.customerName}',
                style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
              ),
              pw.Text(
                'Mobile: ${sale.customerMobile} | Address: ${widget.customer.address}',
              ),
              if (widget.customer.pinCode != null) ...[
                pw.Text('Pincode: ${widget.customer.pinCode}'),
              ],
              pw.Text(
                'Status: ${widget.customer.status} | Country: ${widget.customer.country}',
              ),
              pw.Text('GST No: Not Applicable'),
              pw.SizedBox(height: 16),

              // Items Table
              pw.Table.fromTextArray(
                headers: ['Item', 'HSN', 'Qty', 'MRP', 'Rate', 'Amount'],
                data: sale.items
                    .map(
                      (item) => [
                        item.productName,
                        item.hsnCode,
                        item.quantity.toString(),
                        '₹${item.mrp.toStringAsFixed(2)}',
                        '₹${item.rate.toStringAsFixed(2)}',
                        '₹${item.amount.toStringAsFixed(2)}',
                      ],
                    )
                    .toList(),
              ),
              pw.SizedBox(height: 16),

              // Totals
              pw.Container(
                padding: pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.green),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Subtotal:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text('₹${sale.subtotal.toStringAsFixed(2)}'),
                      ],
                    ),
                    if (sale.discountPercent > 0) ...[
                      pw.SizedBox(height: 4),
                      pw.Row(
                        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                        children: [
                          pw.Text(
                            'Discount (${sale.discountPercent}%):',
                            style: pw.TextStyle(color: PdfColors.red),
                          ),
                          pw.Text(
                            '-₹${(sale.subtotal * sale.discountPercent / 100).toStringAsFixed(2)}',
                            style: pw.TextStyle(color: PdfColors.red),
                          ),
                        ],
                      ),
                    ],
                    pw.SizedBox(height: 4),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Taxable Amount:',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          '₹${(sale.subtotal - (sale.subtotal * sale.discountPercent / 100)).toStringAsFixed(2)}',
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'IGST (${sale.gstPercent}%):',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text('₹${sale.gstAmount.toStringAsFixed(2)}'),
                      ],
                    ),
                    pw.SizedBox(height: 4),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'UGST (2.5% Sharing):',
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text(
                          '₹${(sale.gstAmount * 0.025).toStringAsFixed(2)}',
                        ),
                      ],
                    ),
                    pw.Divider(),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Total Amount:',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          '₹${sale.totalAmount.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontSize: 16,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.green,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 12),
                    pw.Container(
                      padding: pw.EdgeInsets.all(8),
                      decoration: pw.BoxDecoration(
                        color: PdfColors.amber100,
                        borderRadius: pw.BorderRadius.circular(4),
                      ),
                      child: pw.Column(
                        children: [
                          pw.Text(
                            'राशि देय / Amount Payable',
                            style: pw.TextStyle(
                              fontSize: 14,
                              fontWeight: pw.FontWeight.bold,
                            ),
                            textAlign: pw.TextAlign.center,
                          ),
                          pw.Text(
                            '₹${sale.totalAmount.toStringAsFixed(2)}',
                            style: pw.TextStyle(
                              fontSize: 16,
                              fontWeight: pw.FontWeight.bold,
                              color: PdfColors.green,
                            ),
                          ),
                          pw.Text(
                            'कुल भुगतान राशि / Total Paid Amount: ₹0.00',
                            style: pw.TextStyle(
                              fontSize: 12,
                              fontStyle: pw.FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              pw.SizedBox(height: 20),

              // Authorization
              pw.Container(
                padding: pw.EdgeInsets.all(12),
                decoration: pw.BoxDecoration(
                  border: pw.Border.all(color: PdfColors.grey),
                  borderRadius: pw.BorderRadius.circular(8),
                ),
                child: pw.Column(
                  children: [
                    pw.Text(
                      'Authorization / प्राधिकरण',
                      style: pw.TextStyle(
                        fontSize: 14,
                        fontWeight: pw.FontWeight.bold,
                      ),
                      textAlign: pw.TextAlign.center,
                    ),
                    pw.SizedBox(height: 20),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Expanded(
                          child: pw.Column(
                            children: [
                              pw.Text(
                                'Customer Signature',
                                style: pw.TextStyle(
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.SizedBox(height: 30),
                              pw.Container(height: 1, color: PdfColors.black),
                              pw.Text(
                                'हस्ताक्षर',
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontStyle: pw.FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                        pw.Expanded(
                          child: pw.Column(
                            children: [
                              pw.Text(
                                'Authorized Signatory',
                                style: pw.TextStyle(
                                  fontSize: 12,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                              ),
                              pw.SizedBox(height: 4),
                              pw.Text(
                                widget.companyData?['name'] ?? 'Company Name',
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontWeight: pw.FontWeight.bold,
                                ),
                                textAlign: pw.TextAlign.center,
                              ),
                              pw.SizedBox(height: 15),
                              pw.Container(height: 1, color: PdfColors.black),
                              pw.Text(
                                'हस्ताक्षर',
                                style: pw.TextStyle(
                                  fontSize: 10,
                                  fontStyle: pw.FontStyle.italic,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );

    return pdf;
  }
}
