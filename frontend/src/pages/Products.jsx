import { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  Plus, 
  Search, 
  Filter, 
  Edit2, 
  Trash2, 
  Package, 
  ArrowRight,
  Hash,
  Activity,
  AlertTriangle,
  ChevronRight,
  Camera,
  ArrowLeft,
  Globe,
  X
} from 'lucide-react';
import api from '../api';
import { uploadImageToCloudinary } from '../utils/cloudinary';


const Products = () => {
  const [products, setProducts] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showAdd, setShowAdd] = useState(false);
  const [searchTerm, setSearchTerm] = useState('');
  const [viewProduct, setViewProduct] = useState(null);
  const [editingId, setEditingId] = useState(null);

  
  const [formData, setFormData] = useState({
    name: '',
    hsnCode: '',
    quantity: 0,
    purchaseRate: 0,
    mrp: 0,
    salesRate: 0,
    type: 'Tablet',
    unit: 'Nos',
    image: ''
  });
  const [uploading, setUploading] = useState(false);


  useEffect(() => {
    fetchProducts();
  }, []);

  const fetchProducts = async () => {
    try {
      const response = await api.get('/products');
      setProducts(response.data);
    } catch (error) {
      console.error('Error:', error);
    } finally {
      setLoading(false);
    }
  };

  const handleEdit = (product) => {
    setFormData({
       name: product.name,
       hsnCode: product.hsnCode || '',
       quantity: product.quantity,
       purchaseRate: product.purchaseRate,
       mrp: product.mrp,
       salesRate: product.salesRate,
       type: product.type,
       unit: product.unit,
       image: product.image || ''
    });
    setEditingId(product._id);
    setShowAdd(true);
  };

  const resetForm = () => {
    setFormData({ name: '', hsnCode: '', quantity: 0, purchaseRate: 0, mrp: 0, salesRate: 0, type: 'Tablet', unit: 'Nos', image: '' });
    setEditingId(null);
    setShowAdd(false);
  };


  const handleSubmit = async (e) => {
    e.preventDefault();
    setUploading(true);
    try {
       if (editingId) {
          await api.put(`/products/${editingId}`, formData);
       } else {
          await api.post('/products', formData);
       }
       resetForm();
       fetchProducts();
    } catch (error) {
       alert('Operation failed');
    } finally {
       setUploading(false);
    }
  };


  const handleImageUpload = async (e) => {
    const file = e.target.files[0];
    if (!file) return;
    
    setUploading(true);
    const imageUrl = await uploadImageToCloudinary(file, "products");
    if (imageUrl) {
      setFormData({ ...formData, image: imageUrl });
    }
    setUploading(false);
  };


  const handleDelete = async (id) => {
    if (!window.confirm('Erase this product from warehouse?')) return;
    try {
       await api.delete(`/products/${id}`);
       fetchProducts();
       if (viewProduct?._id === id) setViewProduct(null);
    } catch (error) {
       alert('Delete failed');
    }
  };

  const filtered = products.filter(p => 
    (p.name || '').toLowerCase().includes(searchTerm.toLowerCase()) ||
    (p.hsnCode || '').includes(searchTerm)
  );

  return (
    <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="space-y-8">
      {viewProduct ? (
        <motion.div key="profile" initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} className="space-y-10">
           <div className="flex items-center justify-between">
              <button onClick={() => setViewProduct(null)} className="p-4 bg-white rounded-2xl shadow-sm border border-slate-100 hover:bg-slate-50 transition-all flex items-center gap-3 font-black text-[10px] uppercase tracking-widest text-slate-500">
                 <ArrowLeft size={16} /> Back to Warehouse
              </button>
              <div className="flex gap-4">
                 <button onClick={() => handleEdit(viewProduct)} className="p-4 bg-emerald-50 text-emerald-600 rounded-2xl flex items-center gap-2 font-black text-[10px] uppercase tracking-widest hover:bg-emerald-100"><Edit2 size={16} /> Edit Details</button>
                 <button onClick={() => handleDelete(viewProduct._id)} className="p-4 bg-rose-50 text-rose-500 rounded-2xl flex items-center gap-2 font-black text-[10px] uppercase tracking-widest hover:bg-rose-100"><Trash2 size={16} /> Remove SKU</button>
              </div>
           </div>

           <div className="grid grid-cols-1 lg:grid-cols-3 gap-10">
              <div className="lg:col-span-1 space-y-10">
                 <div className="bg-white rounded-[3rem] p-12 border border-slate-100 shadow-xl relative overflow-hidden flex flex-col items-center text-center">
                    <div className="absolute top-0 left-0 w-full h-2 bg-emerald-600" />
                    {viewProduct.image ? (
                       <img src={viewProduct.image} className="w-40 h-40 rounded-[2.5rem] object-cover mb-8 shadow-2xl" />
                    ) : (
                       <div className="w-40 h-40 bg-slate-50 text-slate-200 rounded-[2.5rem] flex items-center justify-center mb-8 border border-slate-100 italic">
                          <Package size={64} />
                       </div>
                    )}
                    <h2 className="text-3xl font-black text-slate-900 tracking-tighter mb-2">{viewProduct.name}</h2>
                    <div className="flex items-center gap-3 mb-6">
                       <span className="px-3 py-1 bg-emerald-50 text-emerald-600 rounded-lg text-[10px] font-black uppercase tracking-widest leading-none flex items-center gap-1.5"><Activity size={12} /> {viewProduct.type}</span>
                       <span className="px-3 py-1 bg-slate-50 text-slate-500 rounded-lg text-[10px] font-black uppercase tracking-widest leading-none flex items-center gap-1.5"><Hash size={12} /> HSN: {viewProduct.hsnCode}</span>
                    </div>
                    
                    <div className="w-full h-px bg-slate-50 my-8" />
                    
                    <div className="w-full grid grid-cols-2 gap-8">
                       <div className="text-left space-y-1">
                          <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Base Cost</p>
                          <p className="text-xl font-black text-slate-900 leading-none">₹{viewProduct.purchaseRate}</p>
                       </div>
                       <div className="text-right space-y-1">
                          <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest">Maximum retail</p>
                          <p className="text-xl font-black text-slate-900 leading-none">₹{viewProduct.mrp}</p>
                       </div>
                    </div>
                 </div>
              </div>

              <div className="lg:col-span-2 space-y-10">
                 <div className="bg-emerald-950 rounded-[3rem] p-12 text-white relative overflow-hidden shadow-2xl">
                    <div className="absolute top-0 right-0 w-64 h-64 bg-emerald-500/10 rounded-full translate-x-32 -translate-y-32" />
                    <div className="relative z-10 flex flex-col md:flex-row items-center justify-between gap-10">
                       <div className="space-y-6">
                          <div>
                             <p className="text-[10px] font-black uppercase tracking-[0.3em] text-emerald-500 mb-4">Real-Time Market Valuation</p>
                             <h3 className="text-7xl font-black tracking-tighter text-white">₹{viewProduct.salesRate}</h3>
                          </div>
                          <div className="flex items-center gap-10">
                             <div className="space-y-2">
                                <p className="text-[10px] font-black uppercase text-emerald-600 tracking-widest">Profit / Unit</p>
                                <p className="text-2xl font-black text-emerald-400 leading-none">₹{(viewProduct.salesRate - viewProduct.purchaseRate).toFixed(2)}</p>
                             </div>
                             <div className="w-px h-10 bg-emerald-800" />
                             <div className="space-y-2">
                                <p className="text-[10px] font-black uppercase text-emerald-600 tracking-widest">Margin %</p>
                                <p className="text-2xl font-black text-emerald-400 leading-none">{(((viewProduct.salesRate - viewProduct.purchaseRate) / viewProduct.purchaseRate) * 100).toFixed(1)}%</p>
                             </div>
                          </div>
                       </div>
                       <div className="bg-white/5 backdrop-blur-xl rounded-[2.5rem] p-10 border border-white/10 text-center min-w-[200px]">
                          <p className="text-[10px] font-black uppercase text-emerald-500 tracking-widest mb-4">Stock Presence</p>
                          <h4 className="text-5xl font-black mb-2">{viewProduct.quantity}</h4>
                          <p className="text-[10px] font-black uppercase tracking-[0.2em] opacity-40">{viewProduct.unit}</p>
                       </div>
                    </div>
                 </div>
                 
                 <div className="bg-white rounded-[3rem] p-12 border border-slate-100 shadow-sm space-y-10">
                    <h3 className="text-xl font-black text-slate-900 tracking-tight flex items-center gap-3">Warehouse Documentation <ArrowRight size={20} className="text-emerald-500" /></h3>
                    <div className="grid grid-cols-1 md:grid-cols-2 gap-10">
                       <div className="p-8 bg-slate-50 rounded-[2rem] border border-slate-100 space-y-4">
                          <p className="text-[10px] font-black uppercase text-slate-400 tracking-widest">Inventory Health</p>
                          <div className="flex items-center gap-4">
                             <div className={`p-3 rounded-xl ${viewProduct.quantity < 10 ? 'bg-rose-100 text-rose-600' : 'bg-emerald-100 text-emerald-600'}`}>
                                <Activity size={24} />
                             </div>
                             <div>
                                <p className="text-base font-black text-slate-900">{viewProduct.quantity < 10 ? 'Critical Depletion' : 'Stable Supply'}</p>
                                <p className="text-[10px] font-bold text-slate-400 italic">Continuous stock monitoring active.</p>
                             </div>
                          </div>
                       </div>
                       <div className="p-8 bg-slate-50 rounded-[2rem] border border-slate-100 space-y-4">
                          <p className="text-[10px] font-black uppercase text-slate-400 tracking-widest">Regulatory Status</p>
                          <div className="flex items-center gap-4">
                             <div className="p-3 bg-emerald-100 text-emerald-600 rounded-xl">
                                <Globe size={24} />
                             </div>
                             <div>
                                <p className="text-base font-black text-slate-900">Standard Compliance</p>
                                <p className="text-[10px] font-bold text-slate-400 italic">HST/GST standards verified.</p>
                             </div>
                          </div>
                       </div>
                    </div>
                 </div>
              </div>
           </div>
        </motion.div>
      ) : (
        <motion.div key="list" initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="space-y-8">
          {/* Dynamic Header */}
          <div className="flex flex-col lg:flex-row items-center justify-between gap-6 pb-6 border-b border-slate-100">
            <div>
               <h1 className="text-3xl font-black text-slate-900 tracking-tighter">Inventory Warehouse</h1>
               <p className="text-sm font-bold text-slate-400 italic">Manage stock, rates, and pharmaceutical documentation.</p>
            </div>
            <div className="flex items-center gap-4 w-full lg:w-auto">
               <div className="relative flex-1 lg:w-80 group">
                 <Search size={18} className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-300 group-focus-within:text-emerald-500 transition-colors" />
                 <input 
                   placeholder="Search by name or HSN..." 
                   className="input-field border-slate-100 bg-white/50 pl-12 h-[56px] text-sm"
                   value={searchTerm}
                   onChange={(e) => setSearchTerm(e.target.value)}
                 />
               </div>
               <button 
                 onClick={() => setShowAdd(true)}
                 className="btn-primary min-w-[200px] h-[56px] flex items-center justify-center gap-2 active:scale-95 shadow-xl shadow-emerald-500/20"
               >
                 <Plus size={20} /> Register Item
               </button>
            </div>
          </div>

          {/* Stock Health Stats */}
          <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
             <div className="p-6 bg-white rounded-3xl border border-slate-100 shadow-sm flex items-center gap-5">
                <div className="w-14 h-14 bg-emerald-50 text-emerald-600 rounded-2xl flex items-center justify-center shadow-inner"><Package /></div>
                <div>
                   <p className="text-[10px] font-black uppercase text-slate-400 tracking-widest leading-none mb-1.5">Total SKU</p>
                   <h4 className="text-2xl font-black text-slate-900 leading-none">{products.length}</h4>
                </div>
             </div>
             <div className="p-6 bg-amber-50 rounded-3xl border border-amber-100 shadow-sm flex items-center gap-5">
                <div className="w-14 h-14 bg-amber-100/50 text-amber-600 rounded-2xl flex items-center justify-center"><AlertTriangle /></div>
                <div>
                   <p className="text-[10px] font-black uppercase text-amber-400 tracking-widest leading-none mb-1.5">Low Stock</p>
                   <h4 className="text-2xl font-black text-amber-700 leading-none">{products.filter(p => p.quantity < 10).length}</h4>
                </div>
             </div>
          </div>

          {/* Modern Inventory Table */}
          <div className="bg-white rounded-[2.5rem] border border-slate-100 shadow-sm overflow-hidden">
            <div className="overflow-x-auto">
              <table className="w-full text-left">
                <thead>
                  <tr className="bg-slate-50/50">
                    <th className="px-8 py-5 text-[10px] font-black text-slate-400 uppercase tracking-[0.25em]">Item Specs</th>
                    <th className="px-8 py-5 text-[10px] font-black text-slate-400 uppercase tracking-[0.25em]">Rate Details (Buy/MRP/Sell)</th>
                    <th className="px-8 py-5 text-[10px] font-black text-slate-400 uppercase tracking-[0.25em]">Current Stock</th>
                    <th className="px-8 py-5 text-[10px] font-black text-slate-400 uppercase tracking-[0.25em]">Actions</th>
                  </tr>
                </thead>
                <tbody>
                  {loading ? (
                     <tr><td colSpan="4" className="text-center py-20 animate-pulse text-sm font-black uppercase text-slate-300">Synchronizing Inventory...</td></tr>
                  ) : filtered.length === 0 ? (
                     <tr>
                       <td colSpan="4" className="text-center py-32 opacity-30 flex flex-col items-center">
                         <Package size={64} className="mb-4" />
                         <p className="text-sm font-black uppercase tracking-widest leading-none">Warehouse is empty</p>
                       </td>
                     </tr>
                  ) : (
                    filtered.map((p, i) => (
                      <motion.tr key={p._id} initial={{ opacity: 0 }} animate={{ opacity: 1 }} transition={{ delay: i * 0.05 }} className="border-b border-slate-50 hover:bg-emerald-50/20 transition-all group">
                        <td className="px-8 py-6">
                           <div className="flex items-center gap-5">
                              {p.image ? (
                                  <img src={p.image} className="w-12 h-12 rounded-2xl object-cover shadow-sm" />
                               ) : (
                                  <div className="w-12 h-12 bg-slate-100 rounded-2xl flex items-center justify-center text-slate-400 group-hover:bg-white group-hover:text-emerald-500 transition-all shadow-sm">
                                     <Package size={22} />
                                  </div>
                               )}
                              <div>
                                 <p className="text-sm font-black text-slate-900 mb-1">{p.name}</p>
                                 <div className="flex items-center gap-3">
                                    <span className="text-[10px] font-black px-2 py-0.5 bg-slate-100 text-slate-500 rounded uppercase tracking-tighter italic">HSN: {p.hsnCode}</span>
                                    <span className="text-[10px] font-black px-2 py-0.5 bg-emerald-100 text-emerald-600 rounded uppercase tracking-tighter">{p.type}</span>
                                 </div>
                              </div>
                           </div>
                        </td>
                        <td className="px-8 py-6">
                           <div className="space-y-1.5 font-sans">
                             <p className="text-[10px] font-bold text-slate-400 leading-none mb-1 uppercase tracking-tight">Buy: ₹{p.purchaseRate.toLocaleString()}</p>
                             <div className="flex items-center gap-2">
                                <p className="text-sm font-black text-slate-800 tracking-tight leading-none">₹{p.salesRate.toLocaleString()}</p>
                                <span className="text-[10px] font-bold line-through text-slate-300">MRP: ₹{p.mrp.toLocaleString()}</span>
                             </div>
                           </div>
                        </td>
                        <td className="px-8 py-6">
                           <div className="flex items-center gap-4">
                              <div className={`w-3 h-3 rounded-full ${p.quantity < 5 ? 'bg-rose-500 animate-pulse' : p.quantity < 15 ? 'bg-amber-400' : 'bg-emerald-500'}`} />
                              <div>
                                 <p className="text-sm font-black text-slate-900 leading-none mb-1">{p.quantity} {p.unit}</p>
                                 <p className={`text-[9px] font-black uppercase tracking-widest leading-none ${p.quantity < 5 ? 'text-rose-500' : 'text-slate-400'}`}>
                                    {p.quantity === 0 ? 'Out of Stock' : p.quantity < 10 ? 'Low Stock Warning' : 'Healthy Inventory'}
                                 </p>
                              </div>
                           </div>
                        </td>
                         <td className="px-8 py-6">
                            <button 
                             onClick={() => setViewProduct(p)}
                             className="flex items-center gap-2 text-[10px] font-black uppercase text-slate-400 hover:text-emerald-600 transition-all tracking-[0.2em] group-hover:translate-x-2"
                            >
                              Manage <ChevronRight size={14} />
                            </button>
                         </td>
                      </motion.tr>
                    ))
                  )}
                </tbody>
              </table>
            </div>
          </div>
        </motion.div>
      )}

      {/* Advanced Registration Drawer */}
      <AnimatePresence>
        {showAdd && (
          <div className="fixed inset-0 z-[100] flex items-end sm:items-center justify-center sm:p-8">
             <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} exit={{ opacity: 0 }} onClick={() => setShowAdd(false)} className="absolute inset-0 bg-slate-900/60 backdrop-blur-md" />
             <motion.div 
               initial={{ y: '100%' }} animate={{ y: 0 }} exit={{ y: '100%' }}
               className="relative bg-white w-full max-w-2xl rounded-t-[3.5rem] sm:rounded-[3.5rem] shadow-2xl p-10 overflow-hidden custom-scrollbar max-h-[90vh] overflow-y-auto"
             >
                <div className="flex items-center justify-between mb-10">
                   <div>
                      <h2 className="text-3xl font-black text-slate-900 tracking-tighter">Sync New Product</h2>
                      <p className="text-xs font-bold text-slate-400 italic">Enter full pharmaceutical or retail specifications.</p>
                   </div>
                    <button onClick={resetForm} className="w-12 h-12 hover:bg-slate-50 transition-all rounded-2xl flex items-center justify-center bg-slate-100 bg-opacity-50"><X size={20} /></button>
                </div>

                <div className="flex justify-center mb-10">
                    <label className="relative group cursor-pointer">
                       <div className="w-32 h-32 rounded-[2.5rem] bg-slate-50 border-2 border-dashed border-slate-200 flex flex-col items-center justify-center gap-2 group-hover:border-emerald-500 transition-all overflow-hidden">
                          {formData.image ? (
                             <img src={formData.image} className="w-full h-full object-cover" />
                          ) : (
                             <>
                                <Camera size={24} className="text-slate-300 group-hover:text-emerald-500" />
                                <span className="text-[9px] font-black uppercase text-slate-400 group-hover:text-emerald-500 tracking-widest">Photo</span>
                             </>
                          )}
                          {uploading && (
                             <div className="absolute inset-0 bg-white/80 flex items-center justify-center">
                                <div className="w-6 h-6 border-2 border-emerald-500 border-t-transparent rounded-full animate-spin" />
                             </div>
                          )}
                       </div>
                       <input type="file" className="hidden" accept="image/*" onChange={handleImageUpload} />
                    </label>
                 </div>

                <form onSubmit={handleSubmit} className="space-y-8 pb-10">
                   <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                      <div className="space-y-2">
                        <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Item Full Name</label>
                        <input className="input-field" placeholder="e.g. Paracetamol Tablet" value={formData.name} onChange={(e) => setFormData({...formData, name: e.target.value})} required />
                      </div>
                      <div className="space-y-2">
                         <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">HSN Code</label>
                         <input className="input-field" placeholder="0000" value={formData.hsnCode} onChange={(e) => setFormData({...formData, hsnCode: e.target.value})} />
                      </div>
                   </div>

                   <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
                      <div className="space-y-2">
                         <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Product Category</label>
                         <select className="input-field h-[56px] bg-slate-50 font-bold" value={formData.type} onChange={(e) => setFormData({...formData, type: e.target.value})}>
                            <option value="Tablet">💊 Tablet</option>
                            <option value="Injection">💉 Injection</option>
                            <option value="Bottle">🧴 Bottle</option>
                            <option value="Medium">🌡️ Medium</option>
                            <option value="Antibiotic">🛡️ Antibiotic</option>
                            <option value="All-In-One">🌀 All-In-One</option>
                         </select>
                      </div>
                      <div className="space-y-2">
                        <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Unit Type</label>
                        <select className="input-field h-[56px] bg-slate-50 font-bold" value={formData.unit} onChange={(e) => setFormData({...formData, unit: e.target.value})}>
                            <option value="Nos">Units (Nos)</option>
                            <option value="ml">Volume (ml)</option>
                            <option value="mg">Mass (mg)</option>
                            <option value="Bundle">Bundle</option>
                            <option value="Pata">Pata (Strip)</option>
                            <option value="Box">Box</option>
                         </select>
                      </div>
                      <div className="space-y-2">
                         <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Current Quantity</label>
                         <input type="number" className="input-field" placeholder="0" value={formData.quantity} onChange={(e) => setFormData({...formData, quantity: e.target.value})} required />
                      </div>
                   </div>

                   <div className="grid grid-cols-1 md:grid-cols-3 gap-8 p-8 bg-emerald-50 rounded-[3rem] border border-emerald-100">
                      <div className="space-y-2">
                        <label className="text-[10px] font-black text-emerald-700 uppercase tracking-widest ml-1">Purchase Rate</label>
                        <input type="number" className="input-field bg-white border-emerald-100" placeholder="0.00" value={formData.purchaseRate} onChange={(e) => setFormData({...formData, purchaseRate: e.target.value})} required />
                      </div>
                      <div className="space-y-2">
                         <label className="text-[10px] font-black text-emerald-700 uppercase tracking-widest ml-1">MRP Price</label>
                         <input type="number" className="input-field bg-white border-emerald-100" placeholder="0.00" value={formData.mrp} onChange={(e) => setFormData({...formData, mrp: e.target.value})} required />
                      </div>
                      <div className="space-y-2">
                         <label className="text-[10px] font-black text-emerald-700 uppercase tracking-widest ml-1">Selling Rate</label>
                         <input type="number" className="input-field bg-white border-emerald-100 highlight-green" placeholder="0.00" value={formData.salesRate} onChange={(e) => setFormData({...formData, salesRate: e.target.value})} required />
                      </div>
                   </div>

                    <button className="btn-primary w-full h-[72px] text-lg font-black uppercase tracking-[0.1em] flex items-center justify-center gap-4 shadow-2xl shadow-emerald-600/30">
                       {editingId ? 'Update Specifications' : 'Link To Inventory'} <ArrowRight size={24} />
                    </button>

                </form>
             </motion.div>
          </div>
        )}
      </AnimatePresence>

    </motion.div>
  );
};

export default Products;
