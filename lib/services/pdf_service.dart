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

    final copyTypes = ['ORIGINAL FOR RECIPIENT', 'DUPLICATE FOR TRANSPORTER'];

    for (String copyType in copyTypes) {
      pdf.addPage(
        pw.MultiPage(
          theme: pw.ThemeData.withFont(base: font, bold: boldFont),
          pageFormat: PdfPageFormat.a4,
          margin: const pw.EdgeInsets.all(16),
          header: (pw.Context context) {
            return pw.Container(
              alignment: pw.Alignment.topRight,
              margin: const pw.EdgeInsets.only(bottom: 8),
              child: pw.Text(
                copyType,
                style: pw.TextStyle(
                  fontWeight: pw.FontWeight.bold,
                  fontSize: 12,
                  color: PdfColors.grey700,
                ),
              ),
            );
          },
          build: (pw.Context context) {
            bool isTransporter = copyType == 'DUPLICATE FOR TRANSPORTER';

            return [
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
                          pw.Text(
                            '${customer.address}, ${customer.city ?? ''}',
                          ),
                          if (customer.state != null ||
                              customer.pinCode != null)
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
                          pw.Text(
                            '${customer.address}, ${customer.city ?? ''}',
                          ),
                          if (customer.state != null ||
                              customer.pinCode != null)
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

              if (!isTransporter) ...[
                // Standard Products Table (Original for Recipient)
                pw.Text(
                  'Items:',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
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
                            child: pw.Text(
                              '₹${item.amount.toStringAsFixed(2)}',
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),

                pw.SizedBox(height: 16),

                // Subtotal
                pw.Container(
                  padding: const pw.EdgeInsets.all(16),
                  decoration: pw.BoxDecoration(
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
              ] else ...[
                // HSN Summary for Transporter
                pw.Text(
                  'HSN Summary:',
                  style: pw.TextStyle(
                    fontSize: 16,
                    fontWeight: pw.FontWeight.bold,
                  ),
                ),
                pw.SizedBox(height: 8),
                (() {
                  Map<String, Map<String, dynamic>> hsnGroups = {};
                  for (var item in sale.items) {
                    if (!hsnGroups.containsKey(item.hsnCode)) {
                      hsnGroups[item.hsnCode] = {'qty': 0, 'amount': 0.0};
                    }
                    hsnGroups[item.hsnCode]!['qty'] += item.quantity;
                    hsnGroups[item.hsnCode]!['amount'] += item.amount;
                  }

                  List<pw.TableRow> hsnRows = [];
                  double grandQty = 0;
                  double grandTaxable = 0;
                  double grandCgst = 0;
                  double grandSgst = 0;
                  double grandTotalAmount = 0;

                  hsnGroups.forEach((hsn, data) {
                    double groupAmount = data['amount'];
                    int qty = data['qty'];

                    double groupDiscountAmount = sale.subtotal > 0
                        ? (groupAmount / sale.subtotal) *
                              (sale.subtotal * sale.discountPercent / 100)
                        : 0.0;
                    double groupTaxable = groupAmount - groupDiscountAmount;

                    double proportion = sale.subtotal > 0
                        ? (groupTaxable /
                              (sale.subtotal -
                                  (sale.subtotal * sale.discountPercent / 100)))
                        : 0.0;

                    double groupCgst = (sale.gstAmount / 2) * proportion;
                    double groupSgst = (sale.gstAmount / 2) * proportion;
                    double groupTotal = groupTaxable + groupCgst + groupSgst;

                    grandQty += qty;
                    grandTaxable += groupTaxable;
                    grandCgst += groupCgst;
                    grandSgst += groupSgst;
                    grandTotalAmount += groupTotal;

                    hsnRows.add(
                      pw.TableRow(
                        children: [
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(hsn),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(
                              '₹${groupTaxable.toStringAsFixed(2)}',
                            ),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(qty.toString()),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text('₹${groupCgst.toStringAsFixed(2)}'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text('₹${groupSgst.toStringAsFixed(2)}'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text('₹${groupTotal.toStringAsFixed(2)}'),
                          ),
                          pw.Padding(
                            padding: const pw.EdgeInsets.all(4),
                            child: pw.Text(sale.billNumber ?? "Preview"),
                          ),
                        ],
                      ),
                    );
                  });

                  hsnRows.insert(
                    0,
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: tableHeaderColor),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'HSN Code',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Taxable',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Qty',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'CGST',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'SGST',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Total',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Bill No',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                      ],
                    ),
                  );

                  hsnRows.add(
                    pw.TableRow(
                      decoration: pw.BoxDecoration(color: tableHeaderColor),
                      children: [
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            'Total',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            '₹${grandTaxable.toStringAsFixed(2)}',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            grandQty.toInt().toString(),
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            '₹${grandCgst.toStringAsFixed(2)}',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            '₹${grandSgst.toStringAsFixed(2)}',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(
                            '₹${grandTotalAmount.toStringAsFixed(2)}',
                            style: pw.TextStyle(fontWeight: pw.FontWeight.bold),
                          ),
                        ),
                        pw.Padding(
                          padding: const pw.EdgeInsets.all(4),
                          child: pw.Text(''),
                        ),
                      ],
                    ),
                  );

                  return pw.Table(
                    border: pw.TableBorder.all(color: tableBorderColor),
                    children: hsnRows,
                  );
                })(),
              ],

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
    }

    return pdf;
  }
}
