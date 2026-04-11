import { Mail, Phone, Award } from 'lucide-react';

const InvoicePage = ({ sale, shop, customer, type }) => {
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

  const isDuplicate = type === "Duplicate for Transporter";

  return (
    <div className="bg-white p-12 w-[210mm] min-h-[297mm] mx-auto shadow-sm text-slate-800 font-sans border-b-2 border-dashed border-slate-200 last:border-0 relative box-border overflow-hidden">
      {/* Top Meta */}
      <div className="flex justify-between items-start mb-8 text-[10px] uppercase tracking-widest font-bold text-slate-400">
        <span className="text-slate-500 bg-slate-100 px-3 py-1 rounded-full">{type}</span>
        <div className="text-right flex flex-col items-end gap-1">
           <span className="text-emerald-600 bg-emerald-50 px-4 py-1.5 rounded-xl border border-emerald-100 text-[11px] font-black">INVOICE NO: {sale.billId}</span>
        </div>
      </div>

      {/* Corporate Header */}
      <div className="flex flex-col items-center text-center mb-8 border-b border-slate-50 pb-8">
        <h1 className="text-4xl font-black text-emerald-600 tracking-tighter mb-2">{shop?.name || 'INDIAN GOLD HEALTH CARE'}</h1>
        <div className="grid grid-cols-1 gap-1 text-[11px] font-bold text-slate-400 max-w-2xl leading-relaxed">
          <p>{shop?.address || 'VILL- BERAPUR TEMDUI POST- MATHI BAZAR DISTT- VARANASI, 221405'}</p>
          <div className="flex items-center justify-center gap-6 mt-2 font-black text-slate-800 italic uppercase tracking-tighter">
            <span className="flex items-center gap-1.5"><Phone size={10} /> {shop?.mobile || '8833947384'}</span>
            <span className="flex items-center gap-1.5">GSTIN: {shop?.gst || '00ABCDE1234F1Z5'}</span>
          </div>
          <p className="flex items-center justify-center gap-1.5 mt-1 text-slate-400"><Mail size={10} /> {shop?.email || 'indiangoldhealthcare@gmail.com'}</p>
        </div>
      </div>

      {/* Date & Meta Section */}
      <div className="flex justify-between items-center mb-8 px-4">
         <div className="space-y-1">
            <p className="text-[10px] font-black uppercase text-slate-400 tracking-widest leading-none">Date of Supply</p>
            <p className="text-lg font-black text-slate-900 tracking-tighter">{new Date(sale.createdAt).toLocaleDateString()}</p>
         </div>
         <div className="text-right space-y-1">
            <p className="text-[10px] font-black uppercase text-slate-400 tracking-widest leading-none">Time of Issue</p>
            <p className="text-sm font-black text-slate-600 tracking-tight italic">{new Date(sale.createdAt).toLocaleTimeString()}</p>
         </div>
      </div>

      {/* Address Cards */}
      <div className="grid grid-cols-2 gap-6 mb-10">
        <div className="bg-slate-50 p-6 rounded-[2rem] border border-slate-100 flex flex-col justify-between h-full min-h-[160px]">
          <div>
            <h3 className="text-[10px] font-black uppercase text-blue-500 tracking-widest mb-4 flex items-center gap-2">
              <div className="w-1.5 h-1.5 bg-blue-500 rounded-full" />
              Billed To (Consignee)
            </h3>
            <div className="space-y-1.5">
              <p className="text-sm font-black text-slate-900 underline underline-offset-4 decoration-slate-200">{sale.customerName?.toUpperCase()}</p>
              <p className="text-[11px] text-slate-500 font-bold leading-relaxed">{customer?.address || 'N/A'}</p>
              <p className="text-[10px] text-slate-400 font-black uppercase tracking-tighter">
                 {customer?.district && `${customer.district}, `}{customer?.state && `${customer.state}, `}{customer?.country || 'India'}
              </p>
            </div>
          </div>
          <div className="pt-4 mt-4 border-t border-slate-200/50">
             <p className="text-[10px] font-black text-slate-800">📱 {customer?.mobile || 'N/A'}</p>
             <p className="text-[10px] font-black text-emerald-600 tracking-widest">🆔 GST: {customer?.gstNumber || 'UNREGISTERED'}</p>
          </div>
        </div>

        <div className="bg-slate-50 p-6 rounded-[2rem] border border-slate-100 flex flex-col justify-between h-full min-h-[160px]">
          <div>
            <h3 className="text-[10px] font-black uppercase text-amber-500 tracking-widest mb-4 flex items-center gap-2">
              <div className="w-1.5 h-1.5 bg-amber-500 rounded-full" />
              Shipped To (Destination)
            </h3>
            <div className="space-y-1.5">
              <p className="text-sm font-black text-slate-900 underline underline-offset-4 decoration-slate-200">{sale.customerName?.toUpperCase()}</p>
              <p className="text-[11px] text-slate-500 font-bold leading-relaxed">{customer?.shippingAddress || customer?.address || 'N/A'}</p>
              <p className="text-[10px] text-slate-400 font-black uppercase tracking-tighter">
                 {customer?.district && `${customer.district}, `}{customer?.state && `${customer.state}, `}{customer?.country || 'India'}
              </p>
            </div>
          </div>
          <div className="pt-4 mt-4 border-t border-slate-200/50">
             <p className="text-[10px] font-black text-slate-800">✉️ {customer?.email || 'N/A'}</p>
             <p className="text-[10px] font-black opacity-0">PLACEHOLDER</p>
          </div>
        </div>
      </div>

      {/* Dynamic Tables Section */}
      <div className="mb-10 w-full overflow-hidden">
        {!isDuplicate ? (
          <div className="rounded-[1.5rem] border border-slate-100 overflow-hidden shadow-sm">
            <table className="w-full text-left text-xs table-fixed">
              <thead>
                <tr className="bg-slate-900 text-[10px] font-bold uppercase tracking-widest text-white">
                  <th className="px-5 py-4 w-5/12">Description of Goods</th>
                  <th className="px-5 py-4 text-center w-2/12">HSN</th>
                  <th className="px-5 py-4 text-center w-1/12">Qty</th>
                  <th className="px-5 py-4 text-right w-2/12">Rate</th>
                  <th className="px-5 py-4 text-center w-1/12">GST</th>
                  <th className="px-5 py-4 text-right w-2/12">Amount</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {(sale.items || []).map((item, idx) => (
                  <tr key={idx} className="hover:bg-slate-50 transition-colors">
                    <td className="px-5 py-4 font-black text-slate-800 uppercase tracking-tight truncate">{item.name}</td>
                    <td className="px-5 py-4 text-center font-mono text-slate-400">{item.hsnCode || '3004'}</td>
                    <td className="px-5 py-4 text-center font-black">{item.quantity}</td>
                    <td className="px-5 py-4 text-right font-medium">₹{item.salesRate.toFixed(2)}</td>
                    <td className="px-5 py-4 text-center font-bold text-emerald-600">{item.gstRate || 5}%</td>
                    <td className="px-5 py-4 text-right font-black">₹{item.total.toFixed(2)}</td>
                  </tr>
                ))}
              </tbody>
              <tfoot className="bg-slate-50 font-black text-slate-900 border-t-2 border-slate-100">
                <tr>
                   <td colSpan="2" className="px-5 py-4 text-right text-[10px] uppercase tracking-widest text-slate-400">Inventory Totals:</td>
                   <td className="px-5 py-4 text-center text-base leading-none">{(sale.items || []).reduce((acc, i) => acc + (i.quantity || 0), 0)}</td>
                   <td colSpan="2" className="px-5 py-4 text-right text-[10px] uppercase tracking-widest text-slate-400">Total Taxable:</td>
                   <td className="px-5 py-4 text-right text-base font-black tracking-tighter">₹{(sale.subtotal || 0).toFixed(2)}</td>
                </tr>
              </tfoot>
            </table>
          </div>
        ) : (
          <div className="rounded-[1.5rem] border border-slate-100 overflow-hidden shadow-sm">
            <h4 className="px-6 py-4 bg-slate-50 text-[10px] font-black uppercase tracking-widest text-slate-400 border-b border-slate-100 flex items-center justify-between">
               <span>Grouped HSN Summary Report</span>
               <span className="text-emerald-600 font-black italic">Consolidated for Transporter</span>
            </h4>
            <table className="w-full text-left text-xs table-fixed">
              <thead>
                <tr className="bg-slate-50 text-[10px] font-black uppercase tracking-widest text-slate-500 border-b border-slate-100">
                  <th className="px-6 py-4 w-3/12">HSN Code</th>
                  <th className="px-6 py-4 text-right w-2/12">Taxable Val</th>
                  <th className="px-6 py-4 text-center w-1/12">Qty</th>
                  <th className="px-6 py-4 text-right w-2/12">CGST</th>
                  <th className="px-6 py-4 text-right w-2/12">SGST</th>
                  <th className="px-6 py-4 text-right w-2/12">Total</th>
                </tr>
              </thead>
              <tbody className="divide-y divide-slate-100">
                {Object.values(hsnGroups).map((group, idx) => (
                  <tr key={idx} className="font-medium text-slate-600 hover:bg-slate-50 transition-colors">
                    <td className="px-6 py-4 font-mono font-black text-slate-900">{group.hsn}</td>
                    <td className="px-6 py-4 text-right">₹{group.taxable.toFixed(2)}</td>
                    <td className="px-6 py-4 text-center font-black text-slate-900">{group.qty}</td>
                    <td className="px-6 py-4 text-right">₹{group.cgst.toFixed(2)}</td>
                    <td className="px-6 py-4 text-right">₹{group.sgst.toFixed(2)}</td>
                    <td className="px-6 py-4 text-right font-black text-emerald-600 underline decoration-2 decoration-emerald-100 underline-offset-4">₹{group.total.toFixed(2)}</td>
                  </tr>
                ))}
              </tbody>
              <tfoot className="bg-slate-50 font-black text-slate-400 italic">
                 <tr>
                    <td className="px-6 py-4 text-[9px]">Verified Document ID: {sale.billId}</td>
                    <td colSpan="5" className="px-6 py-4 text-right text-[10px] uppercase italic tracking-[0.2em] opacity-40">End of Summary</td>
                 </tr>
              </tfoot>
            </table>
          </div>
        )}
      </div>

      {/* Settlement Section */}
      <div className="grid grid-cols-2 gap-10 mt-10">
         <div className="space-y-4">
            <div className="p-6 bg-slate-50 rounded-[2rem] border border-slate-100 relative overflow-hidden h-full">
               <div className="absolute top-0 left-0 w-1.5 h-full bg-emerald-500" />
               <p className="text-[10px] font-black uppercase text-slate-400 tracking-widest mb-3 leading-none underline decoration-slate-200 decoration-2">Self Declaration</p>
               <p className="text-[11px] font-bold text-slate-500 italic leading-relaxed">
                  Certified that the particulars given above are true and the amount indicated is the actual price of the goods. Subject to Varanasi Jurisdiction.
               </p>
            </div>
         </div>

         <div className="p-8 bg-slate-950 rounded-[2.5rem] text-white shadow-[0_20px_50px_rgba(0,120,80,0.1)] relative overflow-hidden">
            <div className="absolute top-0 right-0 w-40 h-40 bg-emerald-500/20 rounded-full translate-x-16 -translate-y-16 blur-2xl" />
            <div className="relative z-10 flex flex-col justify-between h-full">
               <div className="flex justify-between items-start mb-4">
                  <p className="text-[9px] font-black uppercase tracking-[0.3em] text-emerald-500 leading-tight">Final Settlement Breakdown</p>
                  <Award size={14} className="text-emerald-500 opacity-60" />
               </div>
               <div className="space-y-2 mb-6">
                  <div className="flex justify-between text-[11px] font-bold opacity-60 tracking-tight">
                     <span>Total Taxable:</span>
                     <span>₹{(sale.subtotal || 0).toFixed(2)}</span>
                  </div>
                  <div className="flex justify-between text-[11px] font-bold opacity-60 tracking-tight">
                     <span>GST (5%) Breakdown:</span>
                     <span>₹{(sale.gstAmount || 0).toFixed(2)}</span>
                  </div>
                  <div className="h-px bg-white/10 w-full my-3" />
                  <div className="flex justify-between items-center py-2">
                     <span className="text-[10px] font-black uppercase tracking-[0.2em] text-emerald-500">Net Payable Amount</span>
                     <h4 className="text-4xl font-black tracking-tighter text-white">₹{(sale.grandTotal || 0).toFixed(2)}</h4>
                  </div>
               </div>
               <div className="text-center opacity-30 text-[9px] font-black uppercase tracking-[0.4em] pt-4 border-t border-white/5 whitespace-nowrap">
                  Authorized Corporate Instrument • Indian Gold
               </div>
            </div>
         </div>
      </div>

      {/* Signature & Authentication */}
      <div className="flex justify-between items-end mt-12 pt-8 border-t border-slate-100">
         <div className="space-y-4">
            <div className="flex items-center gap-3">
               <div className="w-10 h-10 rounded-xl bg-emerald-50 text-emerald-600 flex items-center justify-center font-black italic shadow-inner">IG</div>
               <div className="text-[8px] font-black text-slate-400 uppercase tracking-widest italic">Registered Enterprise<br/>ID: 416471628692265</div>
            </div>
         </div>
         <div className="text-center w-64 space-y-2">
           <p className="text-[10px] font-black uppercase text-slate-500 italic opacity-50 mb-8">System Generated Verification Record</p>
           <div className="h-0.5 bg-slate-900 w-full rounded-full" />
           <p className="text-[11px] font-black uppercase text-slate-900 tracking-widest">{shop?.name || 'INDIAN GOLD HEALTH CARE'}</p>
           <p className="text-[8px] font-black text-slate-400 uppercase tracking-widest">(Authorized Signatory)</p>
         </div>
      </div>
    </div>
  );
};

const InvoicePreview = ({ sale, shop, customer }) => {
  if (!sale) return null;

  return (
    <div className="bg-slate-200 p-8 flex flex-col gap-10 min-w-max" id="invoice-preview">
      <InvoicePage sale={sale} shop={shop} customer={customer} type="Original for Recipient" />
      <InvoicePage sale={sale} shop={shop} customer={customer} type="Duplicate for Transporter" />
    </div>
  );
};

export default InvoicePreview;
