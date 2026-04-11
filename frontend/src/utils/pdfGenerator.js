import jsPDF from 'jspdf';
import 'jspdf-autotable';

export const generateInvoicePDF = (sale, shop, customer = null) => {
  try {
    const doc = new jsPDF();
    const pageWidth = doc.internal.pageSize.width;
    const pageHeight = doc.internal.pageSize.height;
    const margin = 15;

    const drawHeader = (doc, type = "ORIGINAL FOR RECIPIENT") => {
      // Top Label
      doc.setFont('helvetica', 'bold');
      doc.setFontSize(7);
      doc.setTextColor(150);
      doc.text(type, pageWidth - margin, 10, { align: 'right' });

      // Company Info
      doc.setFont('helvetica', 'bold');
      doc.setFontSize(24);
      doc.setTextColor(5, 150, 105); // Emerald 600
      doc.text(shop?.name || 'INDIAN GOLD HEALTH CARE', pageWidth / 2, 25, { align: 'center' });
      
      doc.setFontSize(8);
      doc.setTextColor(80);
      doc.setFont('helvetica', 'normal');
      const address = shop?.address || 'VILL- BERAPUR TEMDUI POST- MATHI BAZAR DISTT- VARANASI, varanasi up - 221405';
      const addressLines = doc.splitTextToSize(address, pageWidth - (margin * 4));
      doc.text(addressLines, pageWidth / 2, 32, { align: 'center' });
      
      doc.setFont('helvetica', 'bold');
      doc.setTextColor(30, 41, 59);
      doc.text(`Phone: ${shop?.mobile || '8833947384'} | GST: ${shop?.gst || '00ABCDE1234F1Z5'}`, pageWidth / 2, 42, { align: 'center' });
      doc.setFont('helvetica', 'italic');
      doc.setFontSize(7);
      doc.text(`Email: ${shop?.email || 'indiangoldhealthcare@gmail.com'}`, pageWidth / 2, 46, { align: 'center' });
      
      doc.setDrawColor(230);
      doc.line(margin, 52, pageWidth - margin, 52);

      // Invoice Details
      doc.setFont('helvetica', 'bold');
      doc.setFontSize(10);
      doc.setTextColor(30, 41, 59);
      doc.text(`Date: ${new Date(sale.createdAt).toLocaleDateString()} ${new Date(sale.createdAt).toLocaleTimeString([], {hour: '2-digit', minute:'2-digit'})}`, pageWidth - margin, 62, { align: 'right' });


      // Address Cards
      const cardWidth = (pageWidth - (margin * 3)) / 2;
      const cardHeight = 40;
      const cardY = 68;
      
      // Bill To (Light Blue)
      doc.setFillColor(219, 234, 254); // Blue 100
      doc.roundedRect(margin, cardY, cardWidth, cardHeight, 3, 3, 'F');
      doc.setFont('helvetica', 'bold');
      doc.setFontSize(9);
      doc.setTextColor(37, 99, 235); // Blue 600
      doc.text('Bill To:', margin + 5, cardY + 7);
      
      doc.setFont('helvetica', 'bold');
      doc.setFontSize(9);
      doc.setTextColor(30, 41, 59);
      doc.text(sale.customerName?.toUpperCase() || 'WALK-IN CUSTOMER', margin + 5, cardY + 14);
      
      doc.setFont('helvetica', 'normal');
      doc.setFontSize(7);
      doc.setTextColor(70);
      const custAddr = customer?.address || 'N/A';
      const custAddrLines = doc.splitTextToSize(custAddr, cardWidth - 10);
      doc.text(custAddrLines, margin + 5, cardY + 19);
      
      doc.setFont('helvetica', 'bold');
      doc.text(`Mobile: ${customer?.mobile || 'N/A'}`, margin + 5, cardY + 34);
      doc.text(`GSTIN: ${customer?.gstNumber || 'N/A'}`, margin + 5, cardY + 38);

      // Ship To (Light Orange)
      doc.setFillColor(254, 243, 199); // Amber 100
      doc.roundedRect(margin + cardWidth + margin, cardY, cardWidth, cardHeight, 3, 3, 'F');
      doc.setFont('helvetica', 'bold');
      doc.setTextColor(217, 119, 6); // Amber 600
      doc.text('Ship To:', margin + cardWidth + margin + 5, cardY + 7);
      
      doc.setFont('helvetica', 'bold');
      doc.setTextColor(30, 41, 59);
      doc.text(sale.customerName?.toUpperCase() || 'WALK-IN CUSTOMER', margin + cardWidth + margin + 5, cardY + 14);
      
      doc.setFont('helvetica', 'normal');
      doc.setTextColor(70);
      const shipAddr = customer?.shippingAddress || customer?.address || 'N/A';
      const shipAddrLines = doc.splitTextToSize(shipAddr, cardWidth - 10);
      doc.text(shipAddrLines, margin + cardWidth + margin + 5, cardY + 19);
      
      doc.setFont('helvetica', 'bold');
      doc.text(`Mobile: ${customer?.mobile || 'N/A'}`, margin + cardWidth + margin + 5, cardY + 34);
      doc.text(`GSTIN: ${customer?.gstNumber || 'N/A'}`, margin + cardWidth + margin + 5, cardY + 38);
    };

    // --- PAGE 1: ORIGINAL FOR RECIPIENT ---
    drawHeader(doc, "ORIGINAL FOR RECIPIENT");
    
    doc.setFont('helvetica', 'bold');
    doc.setFontSize(10);
    doc.setTextColor(30, 41, 59);
    doc.text('Items:', margin, 118);

    const itemRows = sale.items.map((i, idx) => [
      i.name.toUpperCase(), 
      '3004', 
      i.quantity, 
      '₹' + i.salesRate.toFixed(2), 
      '5%', 
      '₹' + i.total.toFixed(2)
    ]);

    doc.autoTable({
      startY: 122,
      head: [['Item', 'HSN', 'Qty', 'Rate', 'Tax', 'Amount']],
      body: itemRows,
      theme: 'grid',
      headStyles: { fillColor: [241, 245, 249], textColor: [71, 85, 105], fontSize: 8, fontStyle: 'bold' },
      styles: { fontSize: 8, cellPadding: 3 },
      columnStyles: {
        2: { halign: 'center' },
        3: { halign: 'right' },
        4: { halign: 'center' },
        5: { halign: 'right', fontStyle: 'bold' }
      },
      margin: { left: margin, right: margin }
    });

    let finalY = doc.lastAutoTable.finalY + 10;
    
    // Totals Section (Structured)
    const totalLabelX = pageWidth - margin - 75;
    const totalValueX = pageWidth - margin;
    
    doc.setFont('helvetica', 'bold');
    doc.setFontSize(8);
    doc.setTextColor(100);
    
    doc.text('Total Taxable Value:', totalLabelX, finalY);
    doc.text(`₹${(sale.subtotal || 0).toFixed(2)}`, totalValueX, finalY, { align: 'right' });
    
    doc.text('Total GST (5%):', totalLabelX, finalY + 6);
    doc.text(`₹${(sale.gstAmount || 0).toFixed(2)}`, totalValueX, finalY + 6, { align: 'right' });
    
    doc.setDrawColor(200);
    doc.line(totalLabelX, finalY + 10, totalValueX, finalY + 10);
    
    doc.setFontSize(11);
    doc.setTextColor(30, 41, 59);
    doc.text('Final Amount:', totalLabelX, finalY + 18);
    doc.text(`₹${(sale.grandTotal || 0).toFixed(2)}`, totalValueX, finalY + 18, { align: 'right' });

    // Paid Status Badge
    doc.setDrawColor(5, 150, 105);
    doc.setLineWidth(0.5);
    doc.roundedRect(margin, finalY + 50, 25, 8, 2, 2, 'D');
    doc.setFontSize(7);
    doc.setTextColor(5, 150, 105);
    doc.text('BILL PAID', margin + 12.5, finalY + 55, { align: 'center' });



    // Terms and Signatory
    doc.setFont('helvetica', 'bold');
    doc.setFontSize(8);
    doc.setTextColor(30, 41, 59);
    doc.text('Terms & Conditions:', margin, finalY + 35);
    doc.setFont('helvetica', 'normal');
    doc.setFontSize(7);
    doc.setTextColor(100);
    doc.text('1. Goods once sold will not be taken back.', margin, finalY + 40);
    doc.text('2. Subject to jurisdiction area Varanasi.', margin, finalY + 44);

    doc.setFont('helvetica', 'bold');
    doc.setFontSize(10);
    doc.setTextColor(30, 41, 59);
    doc.text(shop?.name?.toUpperCase() || 'INDIAN GOLD HEALTH CARE', pageWidth - margin - 5, finalY + 35, { align: 'right' });
    doc.line(pageWidth - margin - 60, finalY + 45, pageWidth - margin, finalY + 45);
    doc.setFontSize(8);
    doc.text('Authorized Signatory', pageWidth - margin - 30, finalY + 50, { align: 'center' });

    // --- PAGE 2: DUPLICATE FOR TRANSPORTER (with HSN Summary) ---
    doc.addPage();
    drawHeader(doc, "DUPLICATE FOR TRANSPORTER");
    
    doc.setFont('helvetica', 'bold');
    doc.setFontSize(10);
    doc.setTextColor(30, 41, 59);
    doc.text('HSN Summary:', margin, 118);

    const hsnRows = (sale.items || []).map(item => [
      item.hsnCode || '3004', 
      '₹' + (item.total / 1.05).toFixed(2), 
      item.quantity || 0, 
      '₹' + (((item.total / 1.05) * 0.025)).toFixed(2), 
      '₹' + (((item.total / 1.05) * 0.025)).toFixed(2), 
      '₹' + (item.total || 0).toFixed(2), 
      `BILL-${sale.billId}`
    ]);

    doc.autoTable({
      startY: 122,
      head: [['HSN Code', 'Taxable', 'Qty', 'CGST', 'SGST', 'Total', 'Bill No']],
      body: hsnRows,
      theme: 'grid',
      headStyles: { fillColor: [248, 250, 252], textColor: [30, 41, 59], fontSize: 8, fontStyle: 'bold' },
      styles: { fontSize: 8 },
      margin: { left: margin, right: margin }
    });

    finalY = doc.lastAutoTable.finalY + 20;
    
    // Copy Terms and Signatory from Page 1 to Page 2
    doc.setFont('helvetica', 'bold');
    doc.setFontSize(8);
    doc.setTextColor(30, 41, 59);
    doc.text('Terms & Conditions:', margin, finalY + 35);
    doc.setFont('helvetica', 'normal');
    doc.setFontSize(7);
    doc.setTextColor(100);
    doc.text('1. Goods once sold will not be taken back.', margin, finalY + 40);
    doc.text('2. Subject to jurisdiction area Varanasi.', margin, finalY + 44);

    doc.setFont('helvetica', 'bold');
    doc.setFontSize(10);
    doc.setTextColor(30, 41, 59);
    doc.text(shop?.name?.toUpperCase() || 'INDIAN GOLD HEALTH CARE', pageWidth - margin - 5, finalY + 35, { align: 'right' });
    doc.line(pageWidth - margin - 60, finalY + 45, pageWidth - margin, finalY + 45);
    doc.setFontSize(8);
    doc.text('Authorized Signatory', pageWidth - margin - 30, finalY + 50, { align: 'center' });

    doc.save(`Invoice_${sale.billId}.pdf`);
  } catch (err) {
    console.error('PDF Error:', err);
    alert('PDF Generation Failed: ' + err.message);
  }
};

