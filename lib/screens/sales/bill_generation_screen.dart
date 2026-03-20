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
      debugPrint('Sale created with id: $saleId and ${sale.items.length} items');

      // Update product quantities in inventory
      await _updateProductQuantities();

      // Generate PDF
      debugPrint('Generating PDF for sale ${sale.billNumber}...');
      final pdf = await _generatePdf(sale);
      debugPrint('PDF generation complete. Starting layout preview...');

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

  pw.Widget _buildBillHeader(SaleModel sale, String copyLabel) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Row(
          mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
          children: [
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text(widget.companyData?['name'] ?? 'Company Name', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
                pw.Text(widget.companyData?['address'] ?? ''),
                if (widget.companyData?['pinCode'] != null) pw.Text('Pincode: ${widget.companyData!['pinCode']}'),
                pw.Text('Phone: ${widget.companyData?['mobile'] ?? ''} | GST: ${widget.companyData?['gst'] ?? ''}'),
                pw.Text('State: Maharashtra | Country: India'),
              ],
            ),
            pw.Container(
              padding: pw.EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: pw.BoxDecoration( border: pw.Border.all(color: PdfColors.grey), borderRadius: pw.BorderRadius.circular(4)),
              child: pw.Text(copyLabel, style: pw.TextStyle(fontSize: 9, fontWeight: pw.FontWeight.bold)),
            ),
          ],
        ),
        pw.SizedBox(height: 8),
        pw.Text('Bill No: ${sale.billNumber} | Date: ${sale.saleDate.toString().split(' ')[0]}'),
        pw.Text('Bill To: ${sale.customerName} | Mobile: ${sale.customerMobile} | Address: ${widget.customer.address}'),
        if (widget.customer.pinCode != null) pw.Text('Pincode: ${widget.customer.pinCode}'),
        pw.Text('Status: ${widget.customer.status} | Country: ${widget.customer.country}'),
        pw.SizedBox(height: 8),
        pw.Divider(),
      ],
    );
  }

  pw.Widget _buildBillBody(SaleModel sale) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Table.fromTextArray(
          headers: ['Item', 'HSN', 'Qty', 'MRP', 'Rate', 'Amount'],
          data: sale.items
              .map((item) => [
                    item.productName,
                    item.hsnCode,
                    item.quantity.toString(),
                    '₹${item.mrp.toStringAsFixed(2)}',
                    '₹${item.rate.toStringAsFixed(2)}',
                    '₹${item.amount.toStringAsFixed(2)}',
                  ])
              .toList(),
        ),
        pw.SizedBox(height: 6),
        pw.Container(
          padding: pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.green), borderRadius: pw.BorderRadius.circular(4)),
          child: pw.Column(
            children: [
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Subtotal:'), pw.Text('₹${sale.subtotal.toStringAsFixed(2)}')]),
              if (sale.discountPercent > 0)
                pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Discount (${sale.discountPercent}%):', style: pw.TextStyle(color: PdfColors.red)), pw.Text('-₹${(sale.subtotal * sale.discountPercent / 100).toStringAsFixed(2)}', style: pw.TextStyle(color: PdfColors.red))]),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Taxable Amount:'), pw.Text('₹${(sale.subtotal - (sale.subtotal * sale.discountPercent / 100)).toStringAsFixed(2)}')]),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('IGST (${sale.gstPercent}%):'), pw.Text('₹${sale.gstAmount.toStringAsFixed(2)}')]),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('UGST (2.5% Sharing):'), pw.Text('₹${(sale.gstAmount * 0.025).toStringAsFixed(2)}')]),
              pw.Divider(),
              pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [pw.Text('Total Amount:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)), pw.Text('₹${sale.totalAmount.toStringAsFixed(2)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold, color: PdfColors.green))]),
            ],
          ),
        ),
        pw.SizedBox(height: 8),
        pw.Container(
          padding: pw.EdgeInsets.all(8),
          decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey), borderRadius: pw.BorderRadius.circular(4)),
          child: pw.Column(children: [
            pw.Text('Authorization / प्राधिकरण', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 5),
            pw.Row(mainAxisAlignment: pw.MainAxisAlignment.spaceBetween, children: [
              pw.Column(children: [pw.Text('Customer Signature', style: pw.TextStyle(fontSize: 10)), pw.SizedBox(height: 20), pw.Container(height: 1, width: 80, color: PdfColors.black)]),
              pw.Column(children: [pw.Text('Authorized Signatory', style: pw.TextStyle(fontSize: 10)), pw.SizedBox(height: 20), pw.Container(height: 1, width: 80, color: PdfColors.black)]),
            ]),
          ]),
        ),
      ],
    );
  }

  Future<pw.Document> _generatePdf(SaleModel sale) async {
    final pdf = pw.Document();

    pw.Widget buildPage(String copyLabel) {
      debugPrint('Adding PDF page for: $copyLabel');
      return pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(
            padding: pw.EdgeInsets.symmetric(vertical: 4, horizontal: 6),
            decoration: pw.BoxDecoration(
              color: PdfColors.grey300,
              borderRadius: pw.BorderRadius.circular(4),
            ),
            child: pw.Text(copyLabel, style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold, color: PdfColors.black)),
          ),
          pw.SizedBox(height: 8),
          _buildBillHeader(sale, copyLabel),
          _buildBillBody(sale),
        ],
      );
    }

    debugPrint('Adding first page (Original Copy)');
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(12),
        footer: (pw.Context context) {
          return pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [pw.Text('Page ${context.pageNumber} of ${context.pagesCount}')],
          );
        },
        build: (pw.Context context) => [
          buildPage('ORIGINAL COPY'),
        ],
      ),
    );

    debugPrint('Adding second page (Duplicate Copy)');
    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: pw.EdgeInsets.all(12),
        footer: (pw.Context context) {
          return pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.end,
            children: [pw.Text('Page ${context.pageNumber} of ${context.pagesCount}')],
          );
        },
        build: (pw.Context context) => [
          buildPage('DUPLICATE COPY'),
        ],
      ),
    );

    debugPrint('PDF generation complete with duplicate page added');
    return pdf;
  }
}

