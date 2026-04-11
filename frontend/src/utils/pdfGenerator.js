import jsPDF from 'jspdf';
import 'jspdf-autotable';

export const generateInvoicePDF = (sale, shop, customer = null) => {
  try {
    const doc = new jsPDF();
    const pageWidth = doc.internal.pageSize.width;
    const pageHeight = doc.internal.pageSize.height;
    const margin = 15;

    // HSN Grouping Logic
    const hsnGroups = (sale.items || []).reduce((acc, item) => {
      const hsn = item.hsnCode || '3004';
      const gstRate = item.gstRate || 5;
      const taxable = item.total / (1 + (gstRate / 100));
      const taxTotal = item.total - taxable;
      
      if (!acc[hsn]) {
        acc[hsn] = { hsn, taxable: 0, qty: 0, cgst: 0, sgst: 0, total: 0 };
      }
      acc[hsn].taxable += taxable;
      acc[hsn].qty += item.quantity || 0;
      acc[hsn].cgst += taxTotal / 2;
      acc[hsn].sgst += taxTotal / 2;
      acc[hsn].total += item.total || 0;
      return acc;
    }, {});

    const drawHeader = (doc, type = "ORIGINAL FOR RECIPIENT") => {
      // Top Label
      doc.setFont('helvetica', 'bold');
      doc.setFontSize(7);
      doc.setTextColor(150);
      doc.text(type, pageWidth - margin, 10, { align: 'right' });

      // Invoice No Badge
      doc.setFillColor(5, 150, 105); // Emerald 600
      doc.roundedRect(margin, 8, 45, 8, 2, 2, 'F');
      doc.setFontSize(8);
      doc.setTextColor(255);
      doc.text(`INVOICE NO: ${sale.billId}`, margin + 5, 13.5);

      // Company Info
      doc.setFont('helvetica', 'bold');
      doc.setFontSize(22);
      doc.setTextColor(5, 150, 105); 
      doc.text(shop?.name || 'INDIAN GOLD HEALTH CARE', pageWidth / 2, 25, { align: 'center' });
      
      doc.setFontSize(8);
      doc.setTextColor(100);
      doc.setFont('helvetica', 'normal');
      const address = shop?.address || 'VILL- BERAPUR TEMDUI POST- MATHI BAZAR DISTT- VARANASI, 221405';
      const addressLines = doc.splitTextToSize(address, pageWidth - (margin * 4));
      doc.text(addressLines, pageWidth / 2, 32, { align: 'center' });
      
      doc.setFont('helvetica', 'bold');
      doc.setTextColor(30, 41, 59);
      doc.text(`Phone: ${shop?.mobile || '8833947384'} | GSTIN: ${shop?.gst || '00ABCDE1234F1Z5'}`, pageWidth / 2, 42, { align: 'center' });
      
      doc.setDrawColor(240);
      doc.line(margin, 48, pageWidth - margin, 48);

      // Address Cards
      const cardWidth = (pageWidth - (margin * 3)) / 2;
      const cardHeight = 35;
      const cardY = 55;
      
      // Bill To
      doc.setFillColor(248, 250, 252); 
      doc.roundedRect(margin, cardY, cardWidth, cardHeight, 4, 4, 'F');
      doc.setFont('helvetica', 'bold');
      doc.setFontSize(7);
      doc.setTextColor(37, 99, 235);
      doc.text('CONSIGNEE (BILL TO):', margin + 5, cardY + 6);
      
      doc.setFontSize(9);
      doc.setTextColor(30, 41, 59);
      doc.text(sale.customerName?.toUpperCase() || 'WALK-IN CUSTOMER', margin + 5, cardY + 12);
      
      doc.setFont('helvetica', 'normal');
      doc.setFontSize(7);
      doc.setTextColor(80);
      const custAddr = customer?.address || 'N/A';
      const custAddrLines = doc.splitTextToSize(custAddr, cardWidth - 10);
      doc.text(custAddrLines, margin + 5, cardY + 17);
      
      doc.setFont('helvetica', 'bold');
      doc.text(`Mob: ${customer?.mobile || 'N/A'}`, margin + 5, cardY + 30);

      // Ship To
      doc.setFillColor(248, 250, 252);
      doc.roundedRect(margin + cardWidth + margin, cardY, cardWidth, cardHeight, 4, 4, 'F');
      doc.setFont('helvetica', 'bold');
      doc.setTextColor(217, 119, 6);
      doc.text('DESTINATION (SHIP TO):', margin + cardWidth + margin + 5, cardY + 6);
      
      doc.setFontSize(9);
      doc.setTextColor(30, 41, 59);
      doc.text(sale.customerName?.toUpperCase() || 'WALK-IN CUSTOMER', margin + cardWidth + margin + 5, cardY + 12);
      
      doc.setFont('helvetica', 'normal');
      doc.setTextColor(80);
      const shipAddr = customer?.shippingAddress || customer?.address || 'N/A';
      const shipAddrLines = doc.splitTextToSize(shipAddr, cardWidth - 10);
      doc.text(shipAddrLines, margin + cardWidth + margin + 5, cardY + 17);
      
      doc.setFont('helvetica', 'bold');
      doc.text(`Mob: ${customer?.mobile || 'N/A'}`, margin + cardWidth + margin + 5, cardY + 30);
    };

    // --- PAGE 1: ORIGINAL ---
    drawHeader(doc, "ORIGINAL FOR RECIPIENT");
    
    doc.setFont('helvetica', 'bold');
    doc.setFontSize(9);
    doc.setTextColor(30, 41, 59);
    doc.text(`Supply Date: ${new Date(sale.createdAt).toLocaleDateString()}`, pageWidth - margin, 52, { align: 'right' });

    const itemRows = sale.items.map((i, idx) => [
      i.name.toUpperCase(), 
      i.hsnCode || '3004', 
      i.quantity, 
      'INR ' + i.salesRate.toFixed(2), 
      (i.gstRate || 5) + '%', 
      'INR ' + i.total.toFixed(2)
    ]);

    doc.autoTable({
      startY: 95,
      head: [['Description of Goods', 'HSN/SAC', 'Qty', 'Unit Rate', 'GST %', 'Amount']],
      body: itemRows,
      theme: 'grid',
      headStyles: { fillColor: [15, 23, 42], textColor: [255], fontSize: 8, fontStyle: 'bold', halign: 'center' },
      styles: { fontSize: 8, cellPadding: 3, halign: 'center' },
      columnStyles: {
        0: { halign: 'left', fontStyle: 'bold', cellWidth: 70 },
        5: { halign: 'right', fontStyle: 'bold' }
      },
      margin: { left: margin, right: margin }
    });

    let finalY = doc.lastAutoTable.finalY + 10;
    
    // Summary Box
    doc.setFillColor(15, 23, 42);
    doc.roundedRect(pageWidth - margin - 80, finalY, 80, 25, 3, 3, 'F');
    
    doc.setFont('helvetica', 'bold');
    doc.setFontSize(7);
    doc.setTextColor(200);
    doc.text('Taxable Value:', pageWidth - margin - 75, finalY + 7);
    doc.text(`INR ${(sale.subtotal || 0).toFixed(2)}`, pageWidth - margin - 5, finalY + 7, { align: 'right' });
    
    doc.text('GST (5%) Breakdown:', pageWidth - margin - 75, finalY + 12);
    doc.text(`INR ${(sale.gstAmount || 0).toFixed(2)}`, pageWidth - margin - 5, finalY + 12, { align: 'right' });
    
    doc.setDrawColor(255, 255, 255, 0.2);
    doc.line(pageWidth - margin - 75, finalY + 15, pageWidth - margin - 5, finalY + 15);
    
    doc.setFontSize(10);
    doc.setTextColor(255);
    doc.text('Net Amount:', pageWidth - margin - 75, finalY + 21);
    doc.text(`INR ${(sale.grandTotal || 0).toFixed(2)}`, pageWidth - margin - 5, finalY + 21, { align: 'right' });

    // Terms & Conditions
    doc.setFontSize(7);
    doc.setTextColor(150);
    doc.text('1. Goods once sold will not be taken back.', margin, finalY + 10);
    doc.text('2. Subject to jurisdiction area Varanasi.', margin, finalY + 14);

    // Signature
    doc.setFontSize(9);
    doc.setTextColor(30, 41, 59);
    doc.text(shop?.name || 'INDIAN GOLD HEALTH CARE', pageWidth - margin - 5, finalY + 45, { align: 'right' });
    doc.line(pageWidth - margin - 60, finalY + 55, pageWidth - margin - 5, finalY + 55);
    doc.setFontSize(7);
    doc.text('Authorized Signatory', pageWidth - margin - 32, finalY + 60, { align: 'center' });

    // --- PAGE 2: DUPLICATE ---
    doc.addPage();
    drawHeader(doc, "DUPLICATE FOR TRANSPORTER");
    
    const hsnRows = Object.values(hsnGroups).map(g => [
      g.hsn, 
      'INR ' + g.taxable.toFixed(2), 
      g.qty, 
      'INR ' + g.cgst.toFixed(2), 
      'INR ' + g.sgst.toFixed(2), 
      'INR ' + g.total.toFixed(2)
    ]);

    doc.autoTable({
      startY: 95,
      head: [['HSN Code', 'Taxable Val', 'Qty', 'CGST', 'SGST', 'Total Amount']],
      body: hsnRows,
      theme: 'grid',
      headStyles: { fillColor: [248, 250, 252], textColor: [15, 23, 42], fontSize: 8, fontStyle: 'bold', halign: 'center' },
      styles: { fontSize: 8, cellPadding: 4, halign: 'center' },
      columnStyles: {
        0: { fontStyle: 'bold' },
        5: { fontStyle: 'bold', textColor: [5, 150, 105] }
      },
      margin: { left: margin, right: margin }
    });

    finalY = doc.lastAutoTable.finalY + 15;
    doc.setFontSize(8);
    doc.setTextColor(100);
    doc.text(`Transporter Validation ID: ${sale.billId}`, margin, finalY);
    
    // Copy Signatory
    doc.setFont('helvetica', 'bold');
    doc.setFontSize(9);
    doc.setTextColor(30, 41, 59);
    doc.text(shop?.name || 'INDIAN GOLD HEALTH CARE', pageWidth - margin - 5, finalY + 25, { align: 'right' });
    doc.line(pageWidth - margin - 60, finalY + 35, pageWidth - margin - 5, finalY + 35);
    doc.setFontSize(7);
    doc.text('Authorized Signatory', pageWidth - margin - 32, finalY + 40, { align: 'center' });

    doc.save(`IG_Invoice_${sale.billId}.pdf`);
  } catch (err) {
    console.error('PDF Generation Error:', err);
  }
};
