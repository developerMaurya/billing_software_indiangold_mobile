import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/sale_model.dart';
import '../models/customer_model.dart';

class PdfService {
  Future<pw.Document> generateBillPdf({
    required SaleModel sale,
    required CustomerModel customer,
    required Map<String, dynamic>? companyData,
  }) async {
    final pdf = pw.Document();

    // Load fonts that support Indian Rupee symbol
    final font = await PdfGoogleFonts.hindRegular();
    final boldFont = await PdfGoogleFonts.hindBold();

    final companyBorderColor = PdfColor.fromInt(0xFFA5D6A7); // Green.shade200
    final companyTextColor = PdfColor.fromInt(0xFF388E3C); // Green (text)

    final billToColor = PdfColor.fromInt(0xFFE3F2FD); // Blue.shade50
    final billToBorderColor = PdfColor.fromInt(0xFF90CAF9); // Blue.shade200
    final billToTextColor = PdfColors.blue;

    final shipToColor = PdfColor.fromInt(0xFFFFF3E0); // Orange.shade50
    final shipToBorderColor = PdfColor.fromInt(0xFFFFCC80); // Orange.shade200
    final shipToTextColor = PdfColors.orange;

    final tableHeaderColor = PdfColor.fromInt(0xFFF5F5F5); // Grey.shade100
    final tableBorderColor = PdfColor.fromInt(0xFFE0E0E0); // Grey.shade300

    pdf.addPage(
      pw.MultiPage(
        theme: pw.ThemeData.withFont(base: font, bold: boldFont),
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(16),
        build: (pw.Context context) {
          return [
            // Company Header
            // Company Header
            pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.center,
              children: [
                pw.Text(
                  companyData?['name'] ?? 'Company Name',
                  style: pw.TextStyle(
                    fontSize: 24,
                    fontWeight: pw.FontWeight.bold,
                    color: companyTextColor,
                  ),
                  textAlign: pw.TextAlign.center,
                ),
                pw.SizedBox(height: 8),
                pw.Text(
                  '${companyData?['address'] ?? ''}, ${companyData?['city'] ?? ''}',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  '${companyData?['state'] ?? ''} - ${companyData?['pinCode'] ?? ''}',
                  textAlign: pw.TextAlign.center,
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.SizedBox(height: 4),
                pw.Text(
                  'Phone: ${companyData?['phone'] ?? ''} | GST: ${companyData?['gst'] ?? ''}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  textAlign: pw.TextAlign.center,
                ),
                if (companyData?['email'] != null)
                  pw.Text(
                    'Email: ${companyData!['email']}',
                    style: const pw.TextStyle(fontSize: 12),
                    textAlign: pw.TextAlign.center,
                  ),
              ],
            ),

            pw.SizedBox(height: 16),
            pw.Divider(color: tableBorderColor),
            pw.SizedBox(height: 16),

            // Bill Info
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text(
                  'Bill No: ${sale.billNumber ?? "Preview"}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
                pw.Text(
                  'Date: ${DateFormat('dd-MM-yyyy HH:mm').format(sale.saleDate)}',
                  style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                ),
              ],
            ),

            pw.SizedBox(height: 16),

            // Bill To & Ship To Row
            pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                // Bill To
                pw.Expanded(
                  child: pw.Container(
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: billToColor,
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: billToBorderColor),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Bill To:',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 14,
                            color: billToTextColor,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          customer.name,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text('${customer.address}, ${customer.city ?? ''}'),
                        if (customer.state != null || customer.pinCode != null)
                          pw.Text(
                            '${customer.state ?? ''} - ${customer.pinCode ?? ''}',
                          ),
                        pw.Text('Mobile: ${customer.mobile}'),
                        if (customer.gstNumber != null &&
                            customer.gstNumber!.isNotEmpty)
                          pw.Text(
                            'GSTIN: ${customer.gstNumber}',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
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
                    padding: const pw.EdgeInsets.all(12),
                    decoration: pw.BoxDecoration(
                      color: shipToColor,
                      borderRadius: pw.BorderRadius.circular(8),
                      border: pw.Border.all(color: shipToBorderColor),
                    ),
                    child: pw.Column(
                      crossAxisAlignment: pw.CrossAxisAlignment.start,
                      children: [
                        pw.Text(
                          'Ship To:',
                          style: pw.TextStyle(
                            fontWeight: pw.FontWeight.bold,
                            fontSize: 14,
                            color: shipToTextColor,
                          ),
                        ),
                        pw.SizedBox(height: 8),
                        pw.Text(
                          customer.name,
                          style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                        ),
                        pw.Text('${customer.address}, ${customer.city ?? ''}'),
                        if (customer.state != null || customer.pinCode != null)
                          pw.Text(
                            '${customer.state ?? ''} - ${customer.pinCode ?? ''}',
                          ),
                        pw.Text('Mobile: ${customer.mobile}'),
                        if (customer.gstNumber != null &&
                            customer.gstNumber!.isNotEmpty)
                          pw.Text(
                            'GSTIN: ${customer.gstNumber}',
                            style: pw.TextStyle(
                              fontWeight: pw.FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            pw.SizedBox(height: 16),

            // Products Table
            pw.Text(
              'Items:',
              style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold),
            ),
            pw.SizedBox(height: 8),

            pw.Table(
              border: pw.TableBorder.all(color: tableBorderColor),
              children: [
                pw.TableRow(
                  decoration: pw.BoxDecoration(color: tableHeaderColor),
                  children: [
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Item',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'HSN',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Qty',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'MRP',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Rate',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                    pw.Padding(
                      padding: const pw.EdgeInsets.all(8),
                      child: pw.Text(
                        'Amount',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ),
                  ],
                ),
                ...sale.items.map((item) {
                  return pw.TableRow(
                    children: [
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(item.productName),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(item.hsnCode),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text(item.quantity.toString()),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('₹${item.mrp.toStringAsFixed(2)}'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('₹${item.rate.toStringAsFixed(2)}'),
                      ),
                      pw.Padding(
                        padding: const pw.EdgeInsets.all(8),
                        child: pw.Text('₹${item.amount.toStringAsFixed(2)}'),
                      ),
                    ],
                  );
                }),
              ],
            ),

            pw.SizedBox(height: 16),

            // Totals
            pw.Container(
              padding: const pw.EdgeInsets.all(16),
              decoration: pw.BoxDecoration(
                // REMOVED BACKGROUND COLOR HERE
                borderRadius: pw.BorderRadius.circular(12),
                border: pw.Border.all(color: companyBorderColor),
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
                      pw.Text(
                        '₹${sale.subtotal.toStringAsFixed(2)}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                  if (sale.discountPercent > 0) ...[
                    pw.SizedBox(height: 8),
                    pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(
                          'Discount (${sale.discountPercent}%):',
                          style: pw.TextStyle(color: PdfColors.red),
                        ),
                        pw.Text(
                          '-₹${(sale.subtotal * sale.discountPercent / 100).toStringAsFixed(2)}',
                          style: pw.TextStyle(
                            color: PdfColors.red,
                            fontWeight: pw.FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ],
                  pw.SizedBox(height: 8),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Taxable Amount:',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        '₹${(sale.subtotal - (sale.subtotal * sale.discountPercent / 100)).toStringAsFixed(2)}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'Total GST (${sale.gstPercent}%):',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        '₹${sale.gstAmount.toStringAsFixed(2)}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'IGST / SGST (${(sale.gstPercent / 2).toStringAsFixed(1)}%):',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        '₹${(sale.gstAmount / 2).toStringAsFixed(2)}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                  pw.SizedBox(height: 8),
                  pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        'CGST (${(sale.gstPercent / 2).toStringAsFixed(1)}%):',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                      pw.Text(
                        '₹${(sale.gstAmount / 2).toStringAsFixed(2)}',
                        style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                      ),
                    ],
                  ),
                  pw.Divider(height: 16, thickness: 1),
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

            // Authorization/Signature
            pw.SizedBox(height: 16),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text(
                    companyData?['name'] ?? 'Company Name',
                    style: pw.TextStyle(
                      fontWeight: pw.FontWeight.bold,
                      fontSize: 14,
                    ),
                    textAlign: pw.TextAlign.right,
                  ),
                  pw.SizedBox(height: 40),
                  pw.Container(height: 1, width: 200, color: PdfColors.black),
                  pw.SizedBox(height: 4),
                  pw.Text(
                    'Authorized Signatory',
                    style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                  ),
                ],
              ),
            ),

            pw.SizedBox(height: 32),
            pw.Center(
              child: pw.Container(
                height: 2,
                width: 100,
                color: PdfColors.grey400,
              ),
            ),
          ];
        },
      ),
    );

    // Add HSN summary page
    final hsnSummary = <String, Map<String, dynamic>>{};
    for (final item in sale.items) {
      final hsn = item.hsnCode;
      final amount = item.amount;
      final gst = (sale.gstPercent / 100) * amount;
      final cgst = gst / 2;
      final sgst = gst / 2;
      final totalWithGst = amount + cgst + sgst;

      if (!hsnSummary.containsKey(hsn)) {
        hsnSummary[hsn] = {
          'hsn': hsn,
          'taxable': amount,
          'qty': item.quantity,
          'cgst': cgst,
          'sgst': sgst,
          'totalWithGst': totalWithGst,
          'billNo': sale.billNumber ?? '',
        };
      } else {
        hsnSummary[hsn]!['taxable'] += amount;
        hsnSummary[hsn]!['qty'] += item.quantity;
        hsnSummary[hsn]!['cgst'] += cgst;
        hsnSummary[hsn]!['sgst'] += sgst;
        hsnSummary[hsn]!['totalWithGst'] += totalWithGst;
      }
    }

    final hsnRows = hsnSummary.values.toList();
    double totalTaxable = 0;
    int totalQty = 0;
    double totalCgst = 0;
    double totalSgst = 0;
    double totalWithGst = 0;
    for (final row in hsnRows) {
      totalTaxable += row['taxable'] as double;
      totalQty += row['qty'] as int;
      totalCgst += row['cgst'] as double;
      totalSgst += row['sgst'] as double;
      totalWithGst += row['totalWithGst'] as double;
    }

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(16),
        build: (pw.Context context) {
          return [
            // Header company + bill info + customer
            pw.Text(
              companyData?['name'] ?? 'Company Name',
              style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold),
              textAlign: pw.TextAlign.center,
            ),
            pw.SizedBox(height: 4),
            pw.Text('${companyData?['address'] ?? ''}, ${companyData?['city'] ?? ''}', textAlign: pw.TextAlign.center),
            pw.Text('${companyData?['state'] ?? ''} - ${companyData?['pinCode'] ?? ''}', textAlign: pw.TextAlign.center),
            pw.Text('Phone: ${companyData?['phone'] ?? ''} | GST: ${companyData?['gst'] ?? ''}', textAlign: pw.TextAlign.center),
            pw.Divider(),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Text('Bill No: ${sale.billNumber ?? 'Preview'}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                pw.Text('Date: ${DateFormat('dd-MM-yyyy HH:mm').format(sale.saleDate)}', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
              ],
            ),
            pw.SizedBox(height: 8),
            pw.Row(
              mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
              children: [
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Bill To:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(customer.name),
                      pw.Text('${customer.address}, ${customer.city ?? ''}'),
                      pw.Text('Mobile: ${customer.mobile}'),
                    ],
                  ),
                ),
                pw.SizedBox(width: 12),
                pw.Expanded(
                  child: pw.Column(
                    crossAxisAlignment: pw.CrossAxisAlignment.start,
                    children: [
                      pw.Text('Ship To:', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                      pw.Text(customer.name),
                      pw.Text('${customer.address}, ${customer.city ?? ''}'),
                      pw.Text('Mobile: ${customer.mobile}'),
                    ],
                  ),
                ),
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Text('HSN Summary', style: pw.TextStyle(fontSize: 18, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Table.fromTextArray(
              headers: ['HSN Code', 'Taxable', 'Qty', 'CGST', 'SGST', 'Total w/ GST', 'Bill No'],
              data: hsnRows.map((row) {
                return [
                  row['hsn'],
                  '₹${(row['taxable'] as double).toStringAsFixed(2)}',
                  row['qty'].toString(),
                  '₹${(row['cgst'] as double).toStringAsFixed(2)}',
                  '₹${(row['sgst'] as double).toStringAsFixed(2)}',
                  '₹${(row['totalWithGst'] as double).toStringAsFixed(2)}',
                  row['billNo'],
                ];
              }).toList(),
            ),
            pw.SizedBox(height: 8),
            pw.Text('HSN Totals (row in table below)', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 4),
            pw.Table.fromTextArray(
              headers: ['HSN Code', 'Taxable', 'Qty', 'CGST', 'SGST', 'Total w/ GST', 'Bill No'],
              data: [
                [
                  'TOTAL',
                  '₹${totalTaxable.toStringAsFixed(2)}',
                  totalQty.toString(),
                  '₹${totalCgst.toStringAsFixed(2)}',
                  '₹${totalSgst.toStringAsFixed(2)}',
                  '₹${totalWithGst.toStringAsFixed(2)}',
                  '',
                ],
              ],
            ),
            pw.SizedBox(height: 16),
            pw.Text('HSN Summary Totals', style: pw.TextStyle(fontSize: 16, fontWeight: pw.FontWeight.bold)),
            pw.SizedBox(height: 8),
            pw.Container(
              decoration: pw.BoxDecoration(border: pw.Border.all(color: PdfColors.grey)),
              padding: const pw.EdgeInsets.all(8),
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.start,
                children: [
                  pw.Text('Taxable Total: ₹${totalTaxable.toStringAsFixed(2)}'),
                  pw.Text('Qty Total: $totalQty'),
                  pw.Text('CGST Total: ₹${totalCgst.toStringAsFixed(2)}'),
                  pw.Text('SGST Total: ₹${totalSgst.toStringAsFixed(2)}'),
                  pw.Text('Total w/ GST: ₹${totalWithGst.toStringAsFixed(2)}'),
                ],
              ),
            ),
            pw.SizedBox(height: 12),
            pw.Align(
              alignment: pw.Alignment.centerRight,
              child: pw.Column(
                crossAxisAlignment: pw.CrossAxisAlignment.end,
                children: [
                  pw.Text('Authorized Signatory', style: pw.TextStyle(fontWeight: pw.FontWeight.bold)),
                  pw.SizedBox(height: 30),
                  pw.Container(height: 1, width: 180, color: PdfColors.black),
                  pw.Text('${companyData?['name'] ?? 'Company Name'}', style: pw.TextStyle(fontSize: 10)),
                ],
              ),
            ),
          ];
        },
      ),
    );

    return pdf;
  }
}
