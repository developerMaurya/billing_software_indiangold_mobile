import { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  History, 
  Search, 
  Calendar, 
  Download, 
  FileText, 
  Users, 
  ArrowRight,
  ChevronRight,
  TrendingUp,
  CreditCard,
  Building2,
  Trash2,
  Printer,
  CheckCircle2,
  AlertTriangle,
  Award,
  X
} from 'lucide-react';

import api from '../api';
import { useAuth } from '../context/AuthContext';
import { generateInvoicePDF } from '../utils/pdfGenerator';
import InvoicePreview from '../components/InvoicePreview';


const BillHistory = () => {
  const { shop } = useAuth();
  const [sales, setSales] = useState([]);
  const [loading, setLoading] = useState(true);
  const [searchTerm, setSearchTerm] = useState('');
  const [viewedSale, setViewedSale] = useState(null);
  const [previewSale, setPreviewSale] = useState(null);
  const [selectedIds, setSelectedIds] = useState([]);

  const [isDeleting, setIsDeleting] = useState(false);

  useEffect(() => {
    fetchHistory();
  }, []);

  const fetchHistory = async () => {
    try {
      const response = await api.get('/sales');
      setSales(response.data);
    } catch (error) {
      console.error('Error:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleDelete = async (id) => {
    if (!window.confirm('Delete this record eternally?')) return;
    try {
      await api.delete(`/sales/${id}`);
      setSales(sales.filter(s => s._id !== id));
      setViewedSale(null);
    } catch (error) {
      alert('Delete failed');
    }
  };

  const handleBulkDelete = async () => {
    if (!window.confirm(`Permanently wipe ${selectedIds.length} records?`)) return;
    setIsDeleting(true);
    try {
      await api.post('/sales/bulk-delete', { ids: selectedIds });
      setSales(sales.filter(s => !selectedIds.includes(s._id)));
      setSelectedIds([]);
    } catch (error) {
       alert('Bulk delete failed');
    } finally {
       setIsDeleting(false);
    }
  };

  const toggleSelect = (id) => {
    setSelectedIds(prev => prev.includes(id) ? prev.filter(i => i !== id) : [...prev, id]);
  };

  const filtered = sales.filter(s => 
    (s.billId || '').toLowerCase().includes(searchTerm.toLowerCase()) || 
    (s.customerName || '').toLowerCase().includes(searchTerm.toLowerCase())
  );

  const totalRevenue = sales.reduce((sum, s) => sum + (s.grandTotal || 0), 0);


  return (
    <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="space-y-10 pb-20">
      
      {/* Header */}
      <div className="flex flex-col md:flex-row items-center justify-between gap-8 pb-8 border-b border-slate-100">
         <div>
            <h1 className="text-3xl font-black text-slate-900 tracking-tighter">Transaction Cloud</h1>
            <p className="text-xs font-bold text-slate-400 mt-1 uppercase tracking-widest italic">Historical Ledger & Invoice Management</p>
         </div>
         <div className="flex items-center gap-4 w-full md:w-auto">
            {selectedIds.length > 0 && (
               <motion.button 
                 initial={{ scale: 0.8, opacity: 0 }} 
                 animate={{ scale: 1, opacity: 1 }} 
                 onClick={handleBulkDelete}
                 className="px-6 py-3 bg-rose-500 text-white rounded-2xl text-[10px] font-black uppercase tracking-widest shadow-xl shadow-rose-500/20 flex items-center gap-2"
               >
                 <Trash2 size={14} /> Wipe {selectedIds.length} Records
               </motion.button>
            )}
            <div className="relative flex-1 md:w-80 group">
               <Search size={18} className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-300 group-focus-within:text-emerald-500 transition-colors" />
               <input 
                 placeholder="Search by Bill ID or Client..." 
                 className="input-field border-slate-100 bg-white/50 pl-12 h-[52px] text-xs"
                 value={searchTerm}
                 onChange={(e) => setSearchTerm(e.target.value)}
               />
            </div>
         </div>
      </div>

      {/* Analytics Mini Dashboard */}
      <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
         <div className="p-8 bg-emerald-950 rounded-[2.5rem] text-white shadow-2xl shadow-emerald-900/10 relative overflow-hidden group">
            <TrendingUp size={64} className="absolute -right-6 -top-6 text-emerald-500/10 group-hover:scale-125 transition-transform duration-1000" />
            <p className="text-[10px] font-black uppercase text-emerald-500 tracking-widest mb-4">Total Net Revenue</p>
            <h3 className="text-3xl font-black tracking-tighter">₹{totalRevenue.toLocaleString()}</h3>
            <p className="text-[9px] text-emerald-500/60 font-bold mt-2 italic flex items-center gap-1"><span className="w-1.5 h-1.5 bg-emerald-500 rounded-full animate-pulse" /> Live Settlement</p>
         </div>
         <div className="p-8 bg-white rounded-[2.5rem] border border-slate-100 flex flex-col justify-between group cursor-pointer hover:shadow-xl transition-all duration-500">
            <p className="text-[10px] font-black uppercase text-slate-400 tracking-widest">Invoices Processed</p>
            <div className="flex items-end justify-between">
               <h3 className="text-3xl font-black text-slate-900 tracking-tighter">{sales.length}</h3>
               <div className="w-10 h-10 bg-slate-50 text-slate-300 rounded-xl flex items-center justify-center group-hover:bg-emerald-50 group-hover:text-emerald-500 transition-all"><FileText size={18} /></div>
            </div>
         </div>
      </div>

      {/* Main History Table */}
      <div className="bg-white rounded-[3rem] border border-slate-100 shadow-sm overflow-hidden min-h-[500px]">
         <div className="overflow-x-auto">
            <table className="w-full text-left border-collapse">
               <thead>
                  <tr className="bg-slate-50/50">
                     <th className="px-10 py-6 w-10">
                        <input 
                           type="checkbox" 
                           className="w-5 h-5 accent-emerald-600 rounded-lg cursor-pointer"
                           checked={selectedIds.length === filtered.length && filtered.length > 0}
                           onChange={() => {
                              if(selectedIds.length === filtered.length) setSelectedIds([]);
                              else setSelectedIds(filtered.map(s => s._id));
                           }}
                        />
                     </th>
                     <th className="px-10 py-6 text-[10px] font-black text-slate-400 uppercase tracking-[0.3em] border-b border-slate-100">Invoice Identifier</th>
                     <th className="px-10 py-6 text-[10px] font-black text-slate-400 uppercase tracking-[0.3em] border-b border-slate-100">Client Profile</th>
                     <th className="px-10 py-6 text-[10px] font-black text-slate-400 uppercase tracking-[0.3em] border-b border-slate-100 text-center">Settlement</th>
                     <th className="px-10 py-6 text-[10px] font-black text-slate-400 uppercase tracking-[0.3em] border-b border-slate-100 text-right">Operations</th>
                  </tr>
               </thead>
               <tbody className="divide-y divide-slate-50">
                  {loading ? (
                     <tr><td colSpan="5" className="text-center py-24 text-slate-300 font-black uppercase italic tracking-widest animate-pulse">Syncing Cloud Database...</td></tr>
                  ) : filtered.length === 0 ? (
                     <tr><td colSpan="5" className="text-center py-32 opacity-30 font-black uppercase tracking-widest">No transaction records detected.</td></tr>
                  ) : filtered.map((sale) => (
                     <tr key={sale._id} className={`group transition-all cursor-pointer ${selectedIds.includes(sale._id) ? 'bg-emerald-50/60' : 'hover:bg-slate-50'}`}>
                        <td className="px-10 py-7" onClick={(e) => e.stopPropagation()}>
                           <input 
                              type="checkbox" 
                              className="w-5 h-5 accent-emerald-600 rounded-lg cursor-pointer"
                              checked={selectedIds.includes(sale._id)}
                              onChange={() => toggleSelect(sale._id)}
                           />
                        </td>
                        <td className="px-10 py-7" onClick={() => setPreviewSale(sale)}>
                           <div className="flex items-center gap-4">
                              <div className="w-12 h-12 bg-slate-100 text-slate-500 rounded-2xl flex items-center justify-center font-black transition-all group-hover:bg-emerald-600 group-hover:text-white shadow-sm shadow-emerald-500/10"><FileText size={18} /></div>
                              <div>
                                 <p className="text-sm font-black text-slate-900 leading-none mb-1.5">{sale.billId}</p>
                                 <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest leading-none">{new Date(sale.createdAt).toLocaleDateString()} • {new Date(sale.createdAt).toLocaleTimeString()}</p>
                              </div>
                           </div>
                        </td>
                        <td className="px-10 py-7" onClick={() => setPreviewSale(sale)}>
                           <div className="flex items-center gap-3">
                              <div className="w-8 h-8 rounded-lg bg-emerald-50 text-emerald-600 flex items-center justify-center text-[10px] font-black uppercase">{sale.customerName?.charAt(0) || 'G'}</div>
                              <p className="text-sm font-black text-slate-700 tracking-tight">{sale.customerName}</p>
                           </div>
                        </td>
                        <td className="px-10 py-7 text-center" onClick={() => setPreviewSale(sale)}>
                           <p className="text-lg font-black text-slate-900 tracking-tighter leading-none mb-1">₹{sale.grandTotal.toLocaleString()}</p>
                           <span className="text-[9px] font-black uppercase tracking-widest text-emerald-500 flex items-center justify-center gap-1"><span className="w-1.5 h-1.5 rounded-full bg-emerald-500" /> Settled</span>
                        </td>
                        <td className="px-10 py-7">
                           <div className="flex items-center justify-end gap-3 opacity-100 md:opacity-0 group-hover:opacity-100 transition-all">
                               <button 
                                 onClick={(e) => { e.stopPropagation(); setPreviewSale(sale); }}
                                 className="w-10 h-10 bg-white border border-slate-100 text-slate-400 hover:text-blue-500 hover:border-blue-200 rounded-xl flex items-center justify-center shadow-sm transition-all active:scale-95"
                                 title="View Design"
                               >
                                  <Award size={16} />
                               </button>
                               <button 
                                 onClick={(e) => { e.stopPropagation(); generateInvoicePDF(sale, shop, sale.customer); }}

                                className="w-10 h-10 bg-white border border-slate-100 text-slate-400 hover:text-emerald-500 hover:border-emerald-200 rounded-xl flex items-center justify-center shadow-sm transition-all active:scale-95"
                                title="Download PDF"
                              >
                                 <Download size={16} />
                              </button>
                              <button 
                                onClick={(e) => { e.stopPropagation(); handleDelete(sale._id); }}
                                className="w-10 h-10 bg-white border border-slate-100 text-slate-400 hover:text-rose-500 hover:border-rose-200 rounded-xl flex items-center justify-center shadow-sm transition-all active:scale-95"
                                title="Purge Record"
                              >
                                 <Trash2 size={16} />
                              </button>
                           </div>
                        </td>
                     </tr>
                  ))}
               </tbody>
            </table>
         </div>
      </div>

      {/* Detailed Slide-over Modal */}
      <AnimatePresence>
         {viewedSale && (
            <div className="fixed inset-0 z-[100] flex items-center justify-end">
               <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} onClick={() => setViewedSale(null)} className="absolute inset-0 bg-slate-900/60 backdrop-blur-md" />
               <motion.div initial={{ x: '100%' }} animate={{ x: 0 }} exit={{ x: '100%' }} className="relative bg-white w-full max-w-xl h-full shadow-2xl p-12 overflow-y-auto flex flex-col">
                  <div className="flex items-center justify-between mb-12">
                     <h2 className="text-3xl font-black text-slate-900 tracking-tighter">Bill Intelligence</h2>
                     <button onClick={() => setViewedSale(null)} className="w-12 h-12 bg-slate-50 text-slate-400 rounded-2xl flex items-center justify-center hover:bg-slate-100 transition-all"><X size={20} /></button>
                  </div>

                  <div className="space-y-12 flex-1">
                     <div className="flex items-center justify-between p-8 bg-emerald-50 rounded-[2.5rem] border border-emerald-100 relative overflow-hidden">
                        <div className="relative z-10">
                           <p className="text-[10px] font-black uppercase text-emerald-500 tracking-widest mb-2">Invoice Total Paid</p>
                           <h3 className="text-5xl font-black text-slate-900 tracking-tighter">₹{viewedSale.grandTotal.toLocaleString()}</h3>
                        </div>
                        <Printer size={64} className="text-emerald-500/10 absolute -right-4 -bottom-4 relative z-0" />
                     </div>

                     <div className="grid grid-cols-2 gap-10">
                        <div className="space-y-2">
                           <p className="text-[10px] font-black uppercase text-slate-400 tracking-widest">Digital Identifier</p>
                           <p className="text-sm font-black text-slate-800">{viewedSale.billId}</p>
                        </div>
                        <div className="space-y-2">
                           <p className="text-[10px] font-black uppercase text-slate-400 tracking-widest">Settlement Time</p>
                           <p className="text-sm font-black text-slate-800">{new Date(viewedSale.createdAt).toLocaleString()}</p>
                        </div>
                     </div>

                     <div className="space-y-6">
                        <h4 className="text-[10px] font-black uppercase text-slate-400 tracking-widest border-b border-slate-50 pb-4">Line Items List</h4>
                        <div className="space-y-4">
                           {viewedSale.items.map((item, idx) => (
                              <div key={idx} className="flex items-center justify-between p-5 bg-slate-50/50 rounded-2xl border border-slate-100">
                                 <div>
                                    <p className="text-xs font-black text-slate-900 leading-none mb-1">{item.name}</p>
                                    <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest leading-none">QTY: {item.quantity} | Rate: ₹{item.salesRate}</p>
                                 </div>
                                 <p className="text-sm font-black text-slate-900 tracking-tighter">₹{item.total.toLocaleString()}</p>
                              </div>
                           ))}
                        </div>
                     </div>
                  </div>

                  <div className="pt-12 mt-auto space-y-4">
                     <button 
                        onClick={() => generateInvoicePDF(viewedSale, shop, viewedSale.customer)}
                        className="w-full h-20 bg-emerald-600 hover:bg-emerald-500 text-white rounded-[2.5rem] font-black uppercase tracking-[0.2em] shadow-2xl shadow-emerald-500/20 active:scale-95 transition-all flex items-center justify-center gap-3"
                     >
                        <Download size={22} /> Download Cloud Copy
                     </button>
                     <button 
                        onClick={() => handleDelete(viewedSale._id)}
                        className="w-full h-14 bg-slate-100 hover:bg-rose-50 text-slate-400 hover:text-rose-500 rounded-2xl font-black uppercase tracking-widest text-[10px] transition-all flex items-center justify-center gap-3 border border-transparent hover:border-rose-100"
                     >
                        <AlertTriangle size={16} /> Delete Permanent Record
                     </button>
                  </div>
               </motion.div>
            </div>
         )}
      </AnimatePresence>

      {/* Modern Invoice Design Preview Modal */}
      <AnimatePresence>
         {previewSale && (
            <div className="fixed inset-0 z-[110] flex items-center justify-center p-4 md:p-10">
               <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} onClick={() => setPreviewSale(null)} className="absolute inset-0 bg-slate-950/80 backdrop-blur-xl" />
               <motion.div 
                  initial={{ scale: 0.9, opacity: 0, y: 20 }} 
                  animate={{ scale: 1, opacity: 1, y: 0 }} 
                  exit={{ scale: 0.9, opacity: 0, y: 20 }} 
                  className="relative bg-slate-100 w-full max-w-5xl h-full rounded-[3rem] overflow-hidden flex flex-col shadow-2xl"
               >
                  <div className="flex items-center justify-between px-10 py-6 bg-white border-b border-slate-200">
                     <div>
                        <h2 className="text-xl font-black text-slate-900 tracking-tighter">Premium Bill Design</h2>
                        <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest mt-0.5">Live Concept & Layout Review</p>
                     </div>
                     <div className="flex items-center gap-3">
                        <button 
                           onClick={() => generateInvoicePDF(previewSale, shop, previewSale.customer)}
                           className="px-6 py-3 bg-emerald-600 text-white rounded-2xl text-[10px] font-black uppercase tracking-widest flex items-center gap-2 hover:bg-emerald-500 transition-all shadow-lg shadow-emerald-500/20"
                        >
                           <Download size={14} /> Download PDF
                        </button>
                        <button onClick={() => setPreviewSale(null)} className="w-10 h-10 bg-slate-100 text-slate-400 rounded-xl flex items-center justify-center hover:bg-slate-200 transition-all"><X size={18} /></button>
                     </div>
                  </div>
                  
                  <div className="flex-1 overflow-y-auto p-10 bg-slate-200/50">
                     <div className="mx-auto shadow-2xl scale-[0.8] origin-top md:scale-100 mb-20">
                        <InvoicePreview sale={previewSale} shop={shop} customer={previewSale.customer} />
                     </div>
                  </div>
               </motion.div>
            </div>
         )}
      </AnimatePresence>

    </motion.div>

  );
};

export default BillHistory;
