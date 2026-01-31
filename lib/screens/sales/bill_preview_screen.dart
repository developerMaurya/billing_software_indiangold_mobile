import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../models/customer_model.dart';
import '../../models/sale_model.dart';
import '../../services/sale_service.dart';

class BillPreviewScreen extends StatefulWidget {
  final CustomerModel customer;
  final List<Map<String, dynamic>> selectedProducts;
  final Map<String, dynamic>? companyData;
  final double discountPercent;
  final double gstPercent;
  final bool isInclusiveGst;
  final bool autoGenerate;

  const BillPreviewScreen({
    super.key,
    required this.customer,
    required this.selectedProducts,
    this.companyData,
    required this.discountPercent,
    required this.gstPercent,
    required this.isInclusiveGst,
    this.autoGenerate = false,
  });

  @override
  State<BillPreviewScreen> createState() => _BillPreviewScreenState();
}

class _BillPreviewScreenState extends State<BillPreviewScreen> {
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    if (widget.autoGenerate) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _generateBill();
      });
    }
  }

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
        title: const Text(
          'Bill Preview',
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
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Card(
                elevation: 4,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Company Header
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Column(
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
                              '${widget.companyData?['address'] ?? ''}, ${widget.companyData?['city'] ?? ''}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            Text(
                              '${widget.companyData?['state'] ?? ''} - ${widget.companyData?['pinCode'] ?? ''}',
                              textAlign: TextAlign.center,
                              style: const TextStyle(
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              'Phone: ${widget.companyData?['mobile'] ?? ''} | GST: ${widget.companyData?['gst'] ?? ''}',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                              ),
                              textAlign: TextAlign.center,
                            ),
                            if (widget.companyData?['email'] != null)
                              Text(
                                'Email: ${widget.companyData!['email']}',
                                style: const TextStyle(fontSize: 12),
                                textAlign: TextAlign.center,
                              ),
                          ],
                        ),
                      ),

                      const Divider(height: 32),

                      // Bill Info
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            'Bill No: Preview',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          Text(
                            'Date: ${DateFormat('dd-MM-yyyy HH:mm').format(DateTime.now())}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Bill To & Ship To Row
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          // Bill To
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: Colors.blue.shade200),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Bill To:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.blue,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    widget.customer.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${widget.customer.address}, ${widget.customer.city ?? ''}',
                                  ),
                                  if (widget.customer.state != null ||
                                      widget.customer.pinCode != null)
                                    Text(
                                      '${widget.customer.state ?? ''} - ${widget.customer.pinCode ?? ''}',
                                    ),
                                  Text('Mobile: ${widget.customer.mobile}'),
                                  if (widget.customer.gstNumber != null &&
                                      widget.customer.gstNumber!.isNotEmpty)
                                    Text(
                                      'GSTIN: ${widget.customer.gstNumber}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          // Ship To (Same as Bill To for now)
                          Expanded(
                            child: Container(
                              padding: const EdgeInsets.all(12),
                              decoration: BoxDecoration(
                                color: Colors.orange.shade50,
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(
                                  color: Colors.orange.shade200,
                                ),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Ship To:',
                                    style: TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                      color: Colors.orange,
                                    ),
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    widget.customer.name,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                  Text(
                                    '${widget.customer.address}, ${widget.customer.city ?? ''}',
                                  ),
                                  if (widget.customer.state != null ||
                                      widget.customer.pinCode != null)
                                    Text(
                                      '${widget.customer.state ?? ''} - ${widget.customer.pinCode ?? ''}',
                                    ),
                                  Text('Mobile: ${widget.customer.mobile}'),
                                  if (widget.customer.gstNumber != null &&
                                      widget.customer.gstNumber!.isNotEmpty)
                                    Text(
                                      'GSTIN: ${widget.customer.gstNumber}',
                                      style: const TextStyle(
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Products Table
                      const Text(
                        'Items:',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),

                      Table(
                        border: TableBorder.all(color: Colors.grey.shade300),
                        children: [
                          TableRow(
                            decoration: BoxDecoration(
                              color: Colors.grey.shade100,
                            ),
                            children: [
                              Padding(
                                padding: EdgeInsets.all(8),
                                child: Text(
                                  'Item',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8),
                                child: Text(
                                  'HSN',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8),
                                child: Text(
                                  'Qty',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8),
                                child: Text(
                                  'MRP',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8),
                                child: Text(
                                  'Rate',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              Padding(
                                padding: EdgeInsets.all(8),
                                child: Text(
                                  'Amount',
                                  style: TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                            ],
                          ),
                          ...widget.selectedProducts.map((item) {
                            final product = item['product'];
                            final quantity = item['quantity'] as int;
                            final price = item['price'] as double;
                            return TableRow(
                              children: [
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(product.name),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(product.hsnCode),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(quantity.toString()),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(
                                    '₹${product.mrp.toStringAsFixed(2)}',
                                  ),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text('₹${price.toStringAsFixed(2)}'),
                                ),
                                Padding(
                                  padding: const EdgeInsets.all(8),
                                  child: Text(
                                    '₹${(quantity * price).toStringAsFixed(2)}',
                                  ),
                                ),
                              ],
                            );
                          }),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Totals
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: Colors.green.shade200),
                        ),
                        child: Column(
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Subtotal:',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  '₹${subtotal.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            if (widget.discountPercent > 0) ...[
                              const SizedBox(height: 8),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    'Discount (${widget.discountPercent}%):',
                                    style: const TextStyle(color: Colors.red),
                                  ),
                                  Text(
                                    '-₹${discountAmount.toStringAsFixed(2)}',
                                    style: const TextStyle(
                                      color: Colors.red,
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Taxable Amount:',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  '₹${taxableAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  'IGST (${widget.gstPercent}% ${widget.isInclusiveGst ? 'Inclusive' : 'Exclusive'}):',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                                Text(
                                  '₹${gstAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'UGST (2.5% Sharing):',
                                  style: TextStyle(fontWeight: FontWeight.w500),
                                ),
                                Text(
                                  '₹${(gstAmount * 0.025).toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.w500,
                                  ),
                                ),
                              ],
                            ),
                            const Divider(height: 16, thickness: 1),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total Amount:',
                                  style: TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                                Text(
                                  '₹${totalAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.green,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                          ],
                        ),
                      ), // End of Green Totals Container

                      const SizedBox(height: 32),

                      // Authorization/Signature
                      const SizedBox(height: 16),
                      Align(
                        alignment: Alignment.centerRight,
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              widget.companyData?['name'] ?? 'Company Name',
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                              textAlign: TextAlign.right,
                            ),
                            const SizedBox(height: 40),
                            Container(
                              height: 1,
                              width: 200,
                              color: Colors.black,
                            ),
                            const SizedBox(height: 4),
                            const Text(
                              'Authorized Signatory',
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),

                      const SizedBox(height: 32),
                      Center(
                        child: Container(
                          height: 2,
                          width: 100,
                          color: Colors.grey.shade300,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Row(
              children: [
                Expanded(
                  child: OutlinedButton(
                    onPressed: () => Navigator.pop(context),
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      side: const BorderSide(color: Colors.red),
                      foregroundColor: Colors.red,
                    ),
                    child: const Text('Close'),
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: ElevatedButton(
                    onPressed: isLoading ? null : _generateBill,
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      backgroundColor: Colors.green.shade700,
                      foregroundColor: Colors.white,
                    ),
                    child: isLoading
                        ? const SizedBox(
                            height: 20,
                            width: 20,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('GENERATE BILL'),
                  ),
                ),
              ],
            ),
          ),
        ],
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
      await saleService.createSale(sale);

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

    // Load fonts for Hindi and Rupee symbol support
    final font = await PdfGoogleFonts.notoSansDevanagariRegular();
    final fontBold = await PdfGoogleFonts.notoSansDevanagariBold();

    pdf.addPage(
      pw.Page(
        pageTheme: pw.PageTheme(
          theme: pw.ThemeData.withFont(base: font, bold: fontBold),
        ),
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

              // Bill To & Ship To
              pw.Row(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  // Bill To
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex(
                          '#e3f2fd',
                        ), // Colors.blue.shade50
                        borderRadius: pw.BorderRadius.circular(8),
                        border: pw.Border.all(
                          color: PdfColor.fromHex('#90caf9'),
                        ), // Colors.blue.shade200
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Bill To:',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                              color: PdfColors.blue,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            sale.customerName,
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text(
                            '${widget.customer.address}, ${widget.customer.city ?? ''}',
                          ),
                          if (widget.customer.state != null ||
                              widget.customer.pinCode != null)
                            pw.Text(
                              '${widget.customer.state ?? ''} - ${widget.customer.pinCode ?? ''}',
                            ),
                          pw.Text('Mobile: ${sale.customerMobile}'),
                          if (widget.customer.gstNumber != null &&
                              widget.customer.gstNumber!.isNotEmpty)
                            pw.Text(
                              'GSTIN: ${widget.customer.gstNumber}',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                  pw.SizedBox(width: 12),
                  // Ship To
                  pw.Expanded(
                    child: pw.Container(
                      padding: const pw.EdgeInsets.all(10),
                      decoration: pw.BoxDecoration(
                        color: PdfColor.fromHex(
                          '#fff3e0',
                        ), // Colors.orange.shade50
                        borderRadius: pw.BorderRadius.circular(8),
                        border: pw.Border.all(
                          color: PdfColor.fromHex('#ffcc80'),
                        ), // Colors.orange.shade200
                      ),
                      child: pw.Column(
                        crossAxisAlignment: pw.CrossAxisAlignment.start,
                        children: [
                          pw.Text(
                            'Ship To:',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                              color: PdfColors.orange,
                            ),
                          ),
                          pw.SizedBox(height: 4),
                          pw.Text(
                            sale.customerName,
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                          pw.Text(
                            '${widget.customer.address}, ${widget.customer.city ?? ''}',
                          ),
                          if (widget.customer.state != null ||
                              widget.customer.pinCode != null)
                            pw.Text(
                              '${widget.customer.state ?? ''} - ${widget.customer.pinCode ?? ''}',
                            ),
                          pw.Text('Mobile: ${sale.customerMobile}'),
                          if (widget.customer.gstNumber != null &&
                              widget.customer.gstNumber!.isNotEmpty)
                            pw.Text(
                              'GSTIN: ${widget.customer.gstNumber}',
                              style: pw.TextStyle(
                                fontWeight: pw.FontWeight.bold,
                                fontSize: 10,
                              ),
                            ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
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
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                        pw.Text(
                          '₹${sale.totalAmount.toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            fontSize: 18,
                            fontWeight: pw.FontWeight.bold,
                            color: PdfColors.green,
                          ),
                        ),
                      ],
                    ),
                    pw.SizedBox(height: 8),
                  ],
                ),
              ),

              pw.SizedBox(height: 32),

              // Authorization/Signature (Matching Preview)
              pw.Align(
                alignment: pw.Alignment.centerRight,
                child: pw.Column(
                  crossAxisAlignment: pw.CrossAxisAlignment.end,
                  children: [
                    pw.Text(
                      widget.companyData?['name'] ?? 'Company Name',
                      style: pw.TextStyle(
                        fontWeight: pw.FontWeight.bold,
                        fontSize: 14,
                      ),
                      textAlign: pw.TextAlign.right,
                    ),
                    pw.SizedBox(height: 40),
                    pw.Container(height: 1, width: 150, color: PdfColors.black),
                    pw.SizedBox(height: 4),
                    pw.Text(
                      'Authorized Signatory',
                      style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
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
