import { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  Users, 
  Package, 
  Trash2, 
  Plus, 
  Search, 
  CreditCard, 
  CheckCircle2, 
  Printer, 
  ArrowRight,
  ShoppingCart,
  Percent,
  Hash,
  X,
  FileText,
  ChevronRight,
  ChevronLeft
} from 'lucide-react';
import { generateInvoicePDF } from '../utils/pdfGenerator';
import InvoicePreview from '../components/InvoicePreview';

import api from '../api';

const Sales = () => {
  const [customers, setCustomers] = useState([]);
  const [products, setProducts] = useState([]);
  const [shop, setShop] = useState(null);
  const [loading, setLoading] = useState(true);
  
  // Selection State
  const [selectedCustomer, setSelectedCustomer] = useState(null);
  const [cartItems, setCartItems] = useState([]);
  const [searchItem, setSearchItem] = useState('');
  const [searchCust, setSearchCust] = useState('');
  
  // Modal State
  const [showCust, setShowCust] = useState(false);
  const [showItem, setShowItem] = useState(false);
  const [showPreview, setShowPreview] = useState(false);
  const [activeItem, setActiveItem] = useState(null);
  
  // Billing State
  const [discount, setDiscount] = useState(0);
  const [taxRate, setTaxRate] = useState(5);
  const [gstType, setGstType] = useState('Inclusive');
  
  useEffect(() => {
    fetchInitialData();
  }, []);

  const fetchInitialData = async () => {
    try {
      const [cRes, pRes, sRes] = await Promise.all([
        api.get('/customers'),
        api.get('/products'),
        api.get('/auth/me')
      ]);
      setCustomers(cRes.data);
      if (Array.isArray(pRes.data)) {
         setProducts(pRes.data);
      }
      setShop(sRes.data);
    } catch (err) {
      console.error(err);
    } finally {
      setLoading(false);
    }
  };

  const addItemToCart = (product) => {
    const existing = cartItems.find(i => i.product === product._id);
    if (!existing) {
       setCartItems([...cartItems, {
         product: product._id,
         name: product.name,
         hsnCode: product.hsnCode || '3004',
         mrp: product.mrp || 0,
         quantity: 1,
         salesRate: product.salesRate,
         total: product.salesRate
       }]);
    }
    setActiveItem(product);
    setShowItem(false); // Close warehouse search
  };

  const updateQty = (id, newQty) => {
    if (newQty < 1) {
       setCartItems(cartItems.filter(i => i.product !== id));
       return;
    }
    setCartItems(cartItems.map(i => i.product === id ? { ...i, quantity: newQty, total: newQty * i.salesRate } : i));
  };

  const removeItem = (id) => {
    setCartItems(cartItems.filter(i => i.product !== id));
  };

  // Calculations
  const subtotal = cartItems.reduce((acc, i) => acc + (i.total || 0), 0);
  const discountAmount = (subtotal * discount) / 100;
  const taxableAmount = subtotal - discountAmount;
  const gstAmount = (taxableAmount * taxRate) / 100;
  const grandTotal = taxableAmount + gstAmount;

  const handleCreateBill = async () => {
    if (!selectedCustomer) return alert('Select a customer first!');
    if (cartItems.length === 0) return alert('Add items to cart!');

    try {
      const billData = {
        customerId: selectedCustomer._id,
        customerName: selectedCustomer.name,
        items: cartItems,
        subtotal,
        discount,
        gstType,
        gstAmount,
        grandTotal
      };
      
      const response = await api.post('/sales', billData);
      alert('Bill Generated & Stock Updated!');
      generateInvoicePDF(response.data, shop, selectedCustomer); // Auto-Download PDF after user clicks OK
      setCartItems([]);
      setSelectedCustomer(null);
    } catch (err) {
      alert(err.response?.data?.message || 'Error creating bill');
    }
  };


  if (loading) return <div className="h-screen flex items-center justify-center text-emerald-600 font-bold italic tracking-widest animate-pulse">Initializing Virtual Counter...</div>;

  return (
    <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="max-w-[1400px] mx-auto min-h-screen p-4 md:p-10">
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-10">
        {/* LEFT COLUMN: SHOPPING */}
        <div className="lg:col-span-8 flex flex-col gap-6">
           {/* Header Card */}
           <div className="flex flex-col md:flex-row items-center justify-between bg-white p-6 md:p-8 rounded-[2rem] md:rounded-[2.5rem] border border-slate-100 shadow-sm gap-6 md:gap-8 transition-all">
              <div className="flex items-center gap-5 md:gap-8 w-full md:w-auto">
                 <div className="w-16 h-16 md:w-20 md:h-20 bg-emerald-600 text-white rounded-2xl md:rounded-[2rem] flex items-center justify-center shadow-xl shadow-emerald-500/20 flex-shrink-0">
                    <FileText size={30} className="md:w-9 md:h-9" />
                 </div>
                 <div>
                    <h1 className="text-xl md:text-3xl font-black text-slate-900 tracking-tighter leading-none mb-3 md:mb-4">{shop?.name || 'INDIAN GOLD PHARMA'}</h1>
                    <div className="space-y-1.5 md:space-y-2">
                       <p className="text-[10px] md:text-xs font-black text-emerald-500 uppercase tracking-widest leading-none flex items-center gap-2">GST: {shop?.gstNo || 'REGISTERED'}</p>
                       <p className="text-[10px] md:text-xs font-black text-slate-400 uppercase tracking-widest leading-none flex items-center gap-2">Counter: 01</p>
                       <p className="text-[10px] md:text-xs font-bold text-slate-400 italic">{shop?.address || 'Main Branch Location'}</p>
                    </div>
                 </div>
              </div>
              <div className="text-center md:text-right bg-slate-50 p-6 md:p-8 rounded-[2rem] md:rounded-[2.5rem] border border-slate-100 w-full md:min-w-[240px] md:w-auto">
                 <p className="text-[10px] font-black text-emerald-500 uppercase tracking-widest mb-2">Grand Total Due</p>
                 <h2 className="text-2xl md:text-4xl font-black text-slate-900 tracking-tighter">₹{(grandTotal || 0).toLocaleString()}</h2>
              </div>
           </div>

           {/* Quick Actions */}
           <div className="grid grid-cols-1 md:grid-cols-2 gap-4 md:gap-6">
              <button 
                onClick={async () => {
                  await fetchInitialData();
                  setShowCust(true);
                }} 
                className="p-5 md:p-8 bg-white rounded-[2rem] border border-dashed border-emerald-300 hover:bg-emerald-50 transition-all text-left flex items-center gap-5 md:gap-6"
              >
                 <div className="w-14 h-14 bg-emerald-100 text-emerald-600 rounded-2xl flex items-center justify-center"><Users size={24} /></div>
                 <div>
                    <h3 className="font-black text-slate-800 uppercase tracking-tight">{selectedCustomer ? selectedCustomer.name : 'Select Customer'}</h3>
                    <p className="text-xs font-bold text-slate-400 italic">Click to search clients</p>
                 </div>
              </button>
              <button 
                onClick={async () => {
                  await fetchInitialData();
                  setShowItem(true);
                }} 
                className="p-5 md:p-8 bg-emerald-600 text-white rounded-[2rem] shadow-xl shadow-emerald-500/20 hover:bg-emerald-700 transition-all text-left flex items-center gap-5 md:gap-6"
              >
                 <div className="w-14 h-14 bg-white/20 rounded-2xl flex items-center justify-center"><Plus size={24} /></div>
                 <div>
                    <h3 className="font-black uppercase tracking-tight">Add New Product</h3>
                    <p className="text-xs font-bold text-emerald-100 italic">Browse Warehouse Stock</p>
                 </div>
              </button>
           </div>

           {/* Queue Table */}
           <div className="bg-white rounded-[2.5rem] border border-slate-100 shadow-sm overflow-hidden flex-1 min-h-[500px] flex flex-col">
              <div className="px-10 py-6 border-b border-slate-50 flex items-center justify-between bg-slate-50/50">
                 <span className="text-xs font-black text-slate-400 uppercase tracking-[0.2em] italic">Invoice Queue ({cartItems.length})</span>
              </div>
              <div className="flex-1 overflow-y-auto p-6 space-y-4">
                 {cartItems.length === 0 ? (
                    <div className="flex flex-col items-center justify-center h-full opacity-30 py-32">
                       <ShoppingCart size={80} className="text-slate-100" />
                       <p className="text-sm font-black uppercase tracking-widest mt-4">No items added yet</p>
                    </div>
                 ) : (
                    cartItems.map((item) => (
                      <div key={item.product} className="flex flex-col sm:flex-row items-start sm:items-center justify-between p-5 md:p-6 bg-slate-50/50 rounded-3xl border border-transparent hover:border-emerald-200 transition-all group gap-4">
                         <div className="flex items-center gap-5">
                            <div className="w-12 h-12 bg-white rounded-xl flex items-center justify-center text-emerald-500 shadow-sm border border-slate-100 font-black italic">{item.name.charAt(0)}</div>
                            <div>
                               <p className="text-sm font-black text-slate-900 mb-1">{item.name}</p>
                               <p className="text-[10px] font-black uppercase text-emerald-600 tracking-widest">₹{(item.salesRate || 0).toLocaleString()} &times; {item.quantity}</p>
                            </div>
                         </div>
                         <div className="flex items-center gap-8">
                            <div className="text-right">
                               <p className="text-sm font-black text-slate-900">₹{(item.total || 0).toLocaleString()}</p>
                            </div>
                            <button onClick={() => removeItem(item.product)} className="p-3 text-slate-300 hover:text-rose-500 transition-all"><Trash2 size={20} /></button>
                         </div>
                      </div>
                    ))
                 )}
              </div>
           </div>
        </div>

        {/* RIGHT COLUMN: SUMMARY */}
        <div className="lg:col-span-4 space-y-6">
           <div className="bg-emerald-950 rounded-[3rem] p-10 text-white shadow-2xl relative overflow-hidden border border-white/5">
              <div className="absolute top-0 right-0 w-32 h-32 bg-emerald-500/10 blur-3xl rounded-full -mr-16 -mt-16"></div>
              <h2 className="text-xl font-black mb-8 flex items-center gap-3">Bill Summary <FileText size={20} className="text-emerald-400" /></h2>
              
              <div className="space-y-6">
                <div className="flex justify-between items-center text-slate-400">
                   <span className="text-[10px] font-black uppercase tracking-widest leading-none">Subtotal Gross</span>
                   <span className="text-sm font-black text-white">₹{(subtotal || 0).toLocaleString()}</span>
                </div>
                <div className="flex justify-between items-center">
                   <span className="text-[10px] font-black uppercase tracking-widest text-emerald-500 leading-none">Discount (%)</span>
                   <div className="flex items-center gap-2 bg-white/10 px-3 py-1.5 rounded-xl border border-white/5">
                      <Percent size={12} className="text-emerald-400" />
                      <input type="number" className="bg-transparent w-12 text-right outline-none text-sm font-black text-white" value={discount} onChange={(e) => setDiscount(Number(e.target.value))} />
                   </div>
                </div>
                <div className="pt-6 border-t border-white/5 space-y-4">
                   <div className="flex justify-between items-center">
                      <span className="text-[10px] font-black uppercase tracking-widest text-emerald-500">Tax / GST (%)</span>
                      <div className="flex items-center gap-2 bg-white/10 px-3 py-1.5 rounded-xl border border-white/5">
                         <Hash size={12} className="text-emerald-400" />
                         <input type="number" className="bg-transparent w-12 text-right outline-none text-sm font-black text-white" value={taxRate} onChange={(e) => setTaxRate(Number(e.target.value))} />
                      </div>
                   </div>
                   <div className="flex justify-between items-center text-slate-400">
                      <span className="text-[10px] font-black uppercase tracking-widest">Tax Amount</span>
                      <span className="text-sm font-black text-white">₹{(gstAmount || 0).toLocaleString()}</span>
                   </div>
                </div>

                <div className="pt-8 border-t border-emerald-500/20 mt-8">
                   <p className="text-[10px] font-black uppercase tracking-[0.2em] text-emerald-500 mb-2 italic opacity-80">Net Payable Amount</p>
                   <div className="text-3xl md:text-4xl font-black text-emerald-400 tracking-tighter">₹{(grandTotal || 0).toLocaleString()}</div>
                </div>

                <div className="grid grid-cols-1 gap-4 mt-10">
                   <button 
                     onClick={() => {
                        if(cartItems.length === 0) return alert("Add items first!");
                        setShowPreview(true);
                     }} 
                     className="w-full bg-white/10 hover:bg-white/20 text-white h-14 rounded-2xl font-black uppercase tracking-widest text-xs transition-all flex items-center justify-center gap-3 border border-white/10"
                   >
                      <Printer size={18} /> View Bill Preview
                   </button>
                   <button onClick={handleCreateBill} className="w-full bg-emerald-500 hover:bg-emerald-400 text-emerald-950 h-20 rounded-[2rem] font-black uppercase tracking-[0.2em] shadow-xl shadow-emerald-500/20 transition-all flex items-center justify-center gap-3">
                      <CheckCircle2 size={24} /> Finalize & Save Bill
                   </button>
                </div>
              </div>
           </div>
        </div>
      </div>

      {/* MODAL 1: Product Warehouse */}
      <AnimatePresence>
        {showItem && (
          <div className="fixed inset-0 z-[100] flex items-center justify-center p-6 bg-slate-900/60 backdrop-blur-md">
            <motion.div initial={{ opacity: 0, scale: 0.9 }} animate={{ opacity: 1, scale: 1 }} exit={{ opacity: 0, scale: 0.9 }} className="bg-white w-full max-w-2xl rounded-[3rem] shadow-2xl p-10 max-h-[85vh] flex flex-col">
               <div className="flex items-center justify-between mb-8">
                  <h2 className="text-2xl font-black text-slate-900">Product Warehouse ({products.length})</h2>
                  <div className="flex items-center gap-3">
                     <button onClick={fetchInitialData} className="px-5 py-3 bg-emerald-50 text-emerald-600 rounded-2xl text-[10px] font-black uppercase tracking-widest hover:bg-emerald-100 transition-colors">Sync Stock</button>
                     <button onClick={() => setShowItem(false)} className="p-3 bg-slate-100 rounded-2xl transition-transform active:scale-90"><X size={20} /></button>
                  </div>
               </div>
               <div className="relative mb-6">
                  <Search className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-400" size={20} />
                  <input 
                    placeholder="Search stock inventory..." 
                    className="input-field pl-12 h-16" 
                    value={searchItem}
                    onChange={e => setSearchItem(e.target.value)} 
                  />
               </div>
               <div className="flex-1 overflow-y-auto space-y-3 pr-2 pb-10">
                 {products.filter(p => (p.name || "").toLowerCase().includes(searchItem.toLowerCase())).length === 0 ? (
                    <div className="py-10 text-center opacity-40">
                       <p className="text-sm font-black uppercase tracking-widest text-slate-400">No matching products found in warehouse</p>
                    </div>
                 ) : (
                   products.filter(p => (p.name || "").toLowerCase().includes(searchItem.toLowerCase())).map(p => (
                     <div key={p._id} onClick={() => addItemToCart(p)} className="p-6 bg-slate-50 hover:bg-emerald-50 border-2 border-transparent hover:border-emerald-500 rounded-3xl transition-all cursor-pointer flex items-center justify-between">
                        <div>
                           <p className="text-sm font-black text-slate-900 mb-1">{p.name}</p>
                           <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Stock: {p.quantity} | Rate: ₹{(p.salesRate || 0).toLocaleString()}</p>
                        </div>
                        <ChevronRight size={20} className="text-slate-300" />
                     </div>
                   ))
                 )}
               </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

      {/* MODAL 2: Quantity Editor */}
      <AnimatePresence>
        {activeItem && (
          <div className="fixed inset-0 z-[200] flex items-center justify-center p-6 bg-slate-900/40 backdrop-blur-sm">
             <motion.div initial={{ scale: 0.9, opacity: 0 }} animate={{ scale: 1, opacity: 1 }} exit={{ scale: 0.9, opacity: 0 }} className="bg-white w-full max-w-[340px] rounded-[2.5rem] shadow-2xl p-8 text-center relative border border-slate-100">
                <div className="w-14 h-14 bg-emerald-50 text-emerald-600 rounded-2xl flex items-center justify-center mx-auto mb-6 shadow-inner"><Hash size={24} /></div>
                <h2 className="text-xl font-black text-slate-800 tracking-tight mb-1">{activeItem.name}</h2>
                <p className="text-[11px] font-black text-slate-400 uppercase tracking-[0.2em] mb-8">Price: ₹{(activeItem.salesRate || 0).toLocaleString()}</p>
                <div className="flex items-center justify-center gap-6 mb-8">
                   <button onClick={() => updateQty(activeItem._id, (cartItems.find(i => i.product === activeItem._id)?.quantity || 1) - 1)} className="w-12 h-12 bg-slate-50 hover:bg-rose-50 text-rose-500 rounded-xl flex items-center justify-center text-xl font-black transition-all active:scale-90 shadow-sm border border-slate-100">&minus;</button>
                   <span className="text-4xl font-black text-slate-900 w-16">{(cartItems.find(i => i.product === activeItem._id)?.quantity || 1)}</span>
                   <button onClick={() => updateQty(activeItem._id, (cartItems.find(i => i.product === activeItem._id)?.quantity || 1) + 1)} className="w-12 h-12 bg-slate-50 hover:bg-emerald-50 text-emerald-600 rounded-xl flex items-center justify-center text-xl font-black transition-all active:scale-90 shadow-sm border border-slate-100">+</button>
                </div>
                <div className="p-5 bg-emerald-50/50 rounded-2xl mb-8 border border-emerald-100">
                   <p className="text-[9px] font-black uppercase text-emerald-600 tracking-widest mb-1">Total</p>
                   <h3 className="text-2xl font-black text-slate-900 tracking-tighter">₹{((cartItems.find(i => i.product === activeItem._id)?.quantity || 1) * (activeItem.salesRate || 0)).toLocaleString()}</h3>
                </div>
                <button onClick={() => setActiveItem(null)} className="w-full bg-emerald-600 hover:bg-emerald-500 text-white h-14 rounded-2xl font-black uppercase tracking-[0.1em] text-xs shadow-lg shadow-emerald-600/20 active:scale-95 transition-all">Done & Close</button>
             </motion.div>
          </div>
        )}
      </AnimatePresence>

      {/* MODAL 4: Customer Search */}
      <AnimatePresence>
        {showCust && (
          <div className="fixed inset-0 z-[100] flex items-center justify-center p-6 bg-slate-900/60 backdrop-blur-md">
            <motion.div initial={{ opacity: 0, scale: 0.9 }} animate={{ opacity: 1, scale: 1 }} exit={{ opacity: 0, scale: 0.9 }} className="bg-white w-full max-w-2xl rounded-[3rem] shadow-2xl p-10 max-h-[80vh] flex flex-col">
               <div className="flex items-center justify-between mb-8">
                  <h2 className="text-2xl font-black text-slate-900">Select Account</h2>
                  <div className="flex items-center gap-3">
                     <button onClick={fetchInitialData} className="px-5 py-3 bg-emerald-50 text-emerald-600 rounded-2xl text-[10px] font-black uppercase tracking-widest hover:bg-emerald-100 transition-colors">Sync Data</button>
                     <button onClick={() => setShowCust(false)} className="p-3 bg-slate-100 rounded-2xl"><X size={20} /></button>
                  </div>
               </div>
               <input 
                 placeholder="Find client..." 
                 className="input-field h-16 mb-6" 
                 value={searchCust}
                 onChange={e => setSearchCust(e.target.value)} 
               />
               <div className="flex-1 overflow-y-auto space-y-3 pr-2">
                 {customers.filter(c => c.name.toLowerCase().includes(searchCust.toLowerCase())).map(c => (
                    <div key={c._id} onClick={() => { setSelectedCustomer(c); setShowCust(false); }} className="p-6 bg-slate-50 hover:bg-emerald-50 border-2 border-transparent hover:border-emerald-500 rounded-3xl transition-all cursor-pointer flex items-center justify-between">
                       <div>
                          <p className="text-sm font-black text-slate-900 mb-1">{c.name}</p>
                          <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest">{c.mobile}</p>
                       </div>
                       <ChevronRight size={20} className="text-slate-300" />
                    </div>
                 ))}
               </div>
            </motion.div>
          </div>
        )}
      </AnimatePresence>

      {/* MODAL 5: Live Invoice Preview */}
      <AnimatePresence>
        {showPreview && (
          <div className="fixed inset-0 z-[300] flex items-center justify-center p-6 bg-slate-950/80 backdrop-blur-lg overflow-y-auto">
             <div className="min-h-screen py-32 w-full flex items-start justify-center">
                 <motion.div initial={{ y: 50, opacity: 0 }} animate={{ y: 0, opacity: 1 }} exit={{ y: 50, opacity: 0 }} className="bg-white w-full max-w-5xl rounded-[3rem] shadow-2xl overflow-hidden relative border border-slate-200">
                    <div className="flex items-center justify-between px-10 py-6 bg-white border-b border-slate-200">
                       <div>
                          <h2 className="text-xl font-black text-slate-900 tracking-tighter">Bill Draft Preview</h2>
                          <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest mt-0.5">Review before finalizing</p>
                       </div>
                       <div className="flex items-center gap-3">
                          <button 
                             onClick={() => {
                                setShowPreview(false);
                                generateInvoicePDF({ 
                                  items: cartItems, 
                                  subtotal, 
                                  gstAmount, 
                                  grandTotal, 
                                  billId: 'DRAFT', 
                                  createdAt: new Date(),
                                  customerName: selectedCustomer?.name || 'GUEST'
                                }, shop, selectedCustomer);
                             }} 
                             className="px-6 py-3 bg-emerald-600 text-white rounded-2xl text-[10px] font-black uppercase tracking-widest flex items-center gap-2 hover:bg-emerald-500 transition-all shadow-lg shadow-emerald-500/20"
                          >
                             <Printer size={14} /> Download Draft
                          </button>
                          <button onClick={() => setShowPreview(false)} className="w-10 h-10 bg-slate-100 text-slate-400 rounded-xl flex items-center justify-center hover:bg-slate-200 transition-all"><X size={18} /></button>
                       </div>
                    </div>
                    
                    <div className="p-10 bg-slate-200/50 max-h-[80vh] overflow-y-auto">
                        <div className="mx-auto shadow-2xl scale-[0.8] origin-top md:scale-100 mb-20">
                           <InvoicePreview 
                              sale={{ 
                                 items: cartItems, 
                                 subtotal, 
                                 gstAmount, 
                                 grandTotal, 
                                 billId: 'DRAFT-001', 
                                 createdAt: new Date(),
                                 customerName: selectedCustomer?.name || 'Quick Sale Customer'
                              }} 
                              shop={shop} 
                              customer={selectedCustomer} 
                           />
                        </div>
                    </div>
                 </motion.div>
             </div>
          </div>
        )}
      </AnimatePresence>
    </motion.div>
  );
};

export default Sales;
