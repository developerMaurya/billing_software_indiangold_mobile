import { useState, useEffect } from 'react';
import { motion, AnimatePresence } from 'framer-motion';
import { 
  Plus, 
  Search, 
  Users, 
  Phone, 
  MapPin, 
  Mail, 
  Hash,
  ChevronRight,
  ArrowRight,
  Trash2,
  Edit2,
  User,
  ArrowLeft,
  Smartphone,
  Globe,
  Camera,
  Image as ImageIcon
} from 'lucide-react';
import api from '../api';
import { uploadImageToCloudinary } from '../utils/cloudinary';


const Customers = () => {
  const [customers, setCustomers] = useState([]);
  const [loading, setLoading] = useState(true);
  const [showAdd, setShowAdd] = useState(false);
  const [editingId, setEditingId] = useState(null);
  const [viewCustomer, setViewCustomer] = useState(null);
  const [searchTerm, setSearchTerm] = useState('');
  const [formData, setFormData] = useState({
     name: '', mobile: '', email: '', address: '', gstNumber: '', state: '', country: 'India', image: '', district: ''
  });
  const [uploading, setUploading] = useState(false);

  useEffect(() => {
    fetchCustomers();
  }, []);

  const fetchCustomers = async () => {
    try {
      const response = await api.get('/customers');
      setCustomers(response.data);
    } catch (error) {
      console.error('Error:', error);
    } finally {
      setLoading(false);
    }
  };

  const resetForm = () => {
    setFormData({ name: '', mobile: '', email: '', address: '', gstNumber: '', state: '', country: 'India', image: '', district: '' });
    setEditingId(null);
    setShowAdd(false);
  };

  const handleEdit = (customer) => {
    setFormData({
      name: customer.name,
      mobile: customer.mobile,
      email: customer.email || '',
      address: customer.address || '',
      gstNumber: customer.gstNumber || '',
      state: customer.state || '',
      country: customer.country || 'India',
      image: customer.image || '',
      district: customer.district || ''
    });
    setEditingId(customer._id);
    setShowAdd(true);
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setUploading(true);
    try {
       if (editingId) {
          await api.put(`/customers/${editingId}`, formData);
       } else {
          await api.post('/customers', formData);
       }
       resetForm();
       fetchCustomers();
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
    const imageUrl = await uploadImageToCloudinary(file, "customers");
    if (imageUrl) {
      setFormData({ ...formData, image: imageUrl });
    }
    setUploading(false);
  };


  const handleDelete = async (id) => {
    if (!window.confirm('Erase this client record permanently?')) return;
    try {
      await api.delete(`/customers/${id}`);
      fetchCustomers();
      if (viewCustomer?._id === id) setViewCustomer(null);
    } catch (error) {
      alert('Delete failed');
    }
  };

  const filtered = customers.filter(c => 
    (c.name || '').toLowerCase().includes(searchTerm.toLowerCase()) || 
    (c.mobile || '').includes(searchTerm)
  );

  return (
    <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="space-y-8">
      {viewCustomer ? (
        <motion.div key="profile" initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} className="space-y-10">
           <div className="flex items-center justify-between">
              <button onClick={() => setViewCustomer(null)} className="p-4 bg-white rounded-2xl shadow-sm border border-slate-100 hover:bg-slate-50 transition-all flex items-center gap-3 font-black text-[10px] uppercase tracking-widest text-slate-500">
                 <ArrowLeft size={16} /> Back to Directory
              </button>
              <div className="flex gap-4">
                 <button onClick={() => handleEdit(viewCustomer)} className="p-4 bg-emerald-50 text-emerald-600 rounded-2xl flex items-center gap-2 font-black text-[10px] uppercase tracking-widest hover:bg-emerald-100"><Edit2 size={16} /> Edit Profile</button>
                 <button onClick={() => handleDelete(viewCustomer._id)} className="p-4 bg-rose-50 text-rose-500 rounded-2xl flex items-center gap-2 font-black text-[10px] uppercase tracking-widest hover:bg-rose-100"><Trash2 size={16} /> Delete Record</button>
              </div>
           </div>

           <div className="grid grid-cols-1 lg:grid-cols-3 gap-10">
              <div className="lg:col-span-1 space-y-10">
                 <div className="bg-white rounded-[3rem] p-12 border border-slate-100 shadow-xl relative overflow-hidden flex flex-col items-center text-center">
                    <div className="absolute top-0 right-0 w-32 h-32 bg-emerald-500/5 rounded-full translate-x-10 -translate-y-10" />
                    {viewCustomer.image ? (
                        <img src={viewCustomer.image} className="w-24 h-24 rounded-[2rem] object-cover mb-6 shadow-2xl shadow-emerald-500/30" />
                     ) : (
                        <div className="w-24 h-24 bg-emerald-600 text-white rounded-[2rem] flex items-center justify-center text-4xl font-black mb-6 shadow-2xl shadow-emerald-500/30">
                           {viewCustomer.name.charAt(0)}
                        </div>
                     )}
                    <h2 className="text-3xl font-black text-slate-900 tracking-tighter mb-2">{viewCustomer.name}</h2>
                    <p className="text-xs font-black text-emerald-500 uppercase tracking-widest">Client Established • Mar 2024</p>
                    
                    <div className="w-full h-px bg-slate-50 my-10" />
                    
                    <div className="w-full space-y-6">
                       <div className="flex items-center gap-4 text-left">
                          <div className="w-10 h-10 bg-slate-50 rounded-xl flex items-center justify-center text-slate-400 shrink-0"><Smartphone size={18} /></div>
                          <div>
                             <p className="text-[10px] font-black uppercase text-slate-400 tracking-widest leading-none mb-1.5">Direct Mobile</p>
                             <p className="text-sm font-black text-slate-900 leading-none">{viewCustomer.mobile}</p>
                          </div>
                       </div>
                       <div className="flex items-center gap-4 text-left">
                          <div className="w-10 h-10 bg-slate-50 rounded-xl flex items-center justify-center text-slate-400 shrink-0"><Mail size={18} /></div>
                          <div>
                             <p className="text-[10px] font-black uppercase text-slate-400 tracking-widest leading-none mb-1.5">Email Connectivity</p>
                             <p className="text-sm font-black text-slate-900 leading-none">{viewCustomer.email || 'Unregistered'}</p>
                          </div>
                       </div>
                    </div>
                 </div>
              </div>

              <div className="lg:col-span-2 space-y-10">
                 <div className="bg-white rounded-[3rem] p-12 border border-slate-100 shadow-sm space-y-10">
                    <h3 className="text-xl font-black text-slate-900 tracking-tight flex items-center gap-3">Business Intelligence <ArrowRight size={20} className="text-emerald-500" /></h3>
                    
                    <div className="grid grid-cols-2 gap-10">
                       <div className="space-y-2">
                           <p className="text-[10px] font-black uppercase text-slate-400 tracking-widest">Tax Registration (GST)</p>
                           <p className="text-base font-black text-slate-900 uppercase">#{viewCustomer.gstNumber || 'Unregistered'}</p>
                       </div>
                       <div className="space-y-2">
                           <p className="text-[10px] font-black uppercase text-slate-400 tracking-widest">Client Status</p>
                           <p className="text-base font-black text-emerald-500 uppercase flex items-center gap-2 leading-none"><span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />Active Portfolio</p>
                       </div>
                       <div className="col-span-2 space-y-2 pt-6 border-t border-slate-50">
                           <p className="text-[10px] font-black uppercase text-slate-400 tracking-widest">Registered Address</p>
                           <p className="text-base font-bold text-slate-700 italic leading-relaxed">{viewCustomer.address}, {viewCustomer.district}, {viewCustomer.state}, {viewCustomer.country}</p>
                       </div>
                    </div>

                    <div className="bg-emerald-950 rounded-[2.5rem] p-10 text-white flex items-center justify-between">
                       <div>
                          <p className="text-[10px] font-black uppercase tracking-widest text-emerald-400 mb-2">Transaction History</p>
                          <h4 className="text-3xl font-black tracking-tighter">₹0.00</h4>
                       </div>
                       <button className="px-8 h-14 bg-white text-emerald-950 rounded-2xl font-black uppercase text-xs tracking-widest shadow-xl">Detailed Ledger</button>
                    </div>
                 </div>
              </div>
           </div>
        </motion.div>
      ) : (
        <motion.div key="list" initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="space-y-8">
          {/* Header */}
          <div className="flex flex-col md:flex-row items-center justify-between gap-6 pb-6 border-b border-slate-100">
            <div>
               <h1 className="text-3xl font-black text-slate-900 tracking-tighter">Directory & Clients</h1>
               <p className="text-[10px] md:text-sm font-bold text-slate-400 italic">Manage your customer profiles and registration details.</p>
            </div>
            <div className="flex items-center gap-4 w-full md:w-auto">
               <div className="relative flex-1 md:w-80 group">
                  <Search size={18} className="absolute left-4 top-1/2 -translate-y-1/2 text-slate-300 group-focus-within:text-emerald-500 transition-colors" />
                  <input 
                    placeholder="Search clients..." 
                    className="input-field border-slate-100 bg-white/50 pl-12 h-[52px] text-xs"
                    value={searchTerm}
                    onChange={(e) => setSearchTerm(e.target.value)}
                  />
               </div>
               <button 
                 onClick={() => { resetForm(); setShowAdd(true); }}
                 className="btn-primary min-w-[180px] h-[52px] flex items-center justify-center gap-2 active:scale-95 text-xs font-black uppercase tracking-widest"
               >
                 <Plus size={20} /> Add Client
               </button>
            </div>
          </div>

          {/* Stats Mini Row */}
          <div className="grid grid-cols-1 md:grid-cols-4 gap-6">
             <div className="p-6 bg-white rounded-3xl border border-slate-100 shadow-sm flex items-center gap-6">
                <div className="w-14 h-14 bg-emerald-50 text-emerald-600 rounded-2xl flex items-center justify-center shadow-lg shadow-emerald-500/10"><Users /></div>
                <div>
                   <p className="text-[10px] font-black uppercase text-slate-400 tracking-widest leading-none mb-2">Total Registry</p>
                   <h4 className="text-xl font-black text-slate-900">{customers.length} Accounts</h4>
                </div>
             </div>
          </div>

          {/* Table Container */}
          <div className="bg-white rounded-[2.5rem] border border-slate-100 shadow-sm overflow-hidden min-h-[500px]">
            <div className="overflow-x-auto">
              <table className="w-full text-left border-collapse">
                <thead>
                  <tr className="bg-slate-50/50">
                    <th className="px-8 py-5 text-[10px] font-black text-slate-400 uppercase tracking-[0.25em] border-b border-slate-100">Account Profile</th>
                    <th className="px-8 py-5 text-[10px] font-black text-slate-400 uppercase tracking-[0.25em] border-b border-slate-100">Business Logic</th>
                    <th className="px-8 py-5 text-[10px] font-black text-slate-400 uppercase tracking-[0.25em] border-b border-slate-100">Actions</th>
                  </tr>
                </thead>
                <tbody className="divide-y divide-slate-50">
                  {loading ? (
                    <tr><td colSpan="3" className="text-center py-20 text-slate-400 font-bold uppercase italic tracking-widest animate-pulse">Synchronizing Data...</td></tr>
                  ) : filtered.length === 0 ? (
                    <tr><td colSpan="3" className="text-center py-32 opacity-30 font-black uppercase tracking-widest">No Clients Registered</td></tr>
                  ) : filtered.map((c, i) => (
                    <tr key={c._id} className="group hover:bg-emerald-50/20 transition-all cursor-pointer">
                      <td className="px-8 py-5" onClick={() => setViewCustomer(c)}>
                        <div className="flex items-center gap-4">
                           {c.image ? (
                               <img src={c.image} className="w-12 h-12 rounded-2xl object-cover shadow-sm" />
                            ) : (
                               <div className="w-12 h-12 bg-slate-100 rounded-2xl flex items-center justify-center text-lg font-black text-slate-500 group-hover:bg-emerald-600 group-hover:text-white transition-all shadow-sm">
                                  {c.name.charAt(0)}
                               </div>
                            )}
                           <div>
                              <p className="text-sm font-black text-slate-900 mb-1 leading-none">{c.name}</p>
                              <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest leading-none">{c.mobile}</p>
                           </div>
                        </div>
                      </td>
                      <td className="px-8 py-5" onClick={() => setViewCustomer(c)}>
                         <div className="space-y-1">
                            <p className="text-xs font-bold text-slate-600 italic truncate max-w-[200px]">{c.address || 'Address not registered'}</p>
                            <p className="text-[10px] font-black text-emerald-600 uppercase tracking-widest">GST: {c.gstNumber || 'Unregistered'}</p>
                         </div>
                      </td>
                      <td className="px-8 py-5">
                         <div className="flex items-center gap-3">
                            <button onClick={(e) => { e.stopPropagation(); handleEdit(c); }} className="w-10 h-10 rounded-xl bg-slate-100 text-slate-500 hover:bg-emerald-500 hover:text-white transition-all flex items-center justify-center shadow-sm"><Edit2 size={16} /></button>
                            <button onClick={(e) => { e.stopPropagation(); handleDelete(c._id); }} className="w-10 h-10 rounded-xl bg-slate-100 text-slate-300 hover:bg-rose-500 hover:text-white transition-all flex items-center justify-center shadow-sm"><Trash2 size={16} /></button>
                            <button onClick={() => setViewCustomer(c)} className="w-10 h-10 rounded-xl bg-white border border-slate-100 text-slate-300 hover:text-emerald-500 hover:border-emerald-200 transition-all flex items-center justify-center shadow-sm ml-4"><ChevronRight size={18} /></button>
                         </div>
                      </td>
                    </tr>
                  ))}
                </tbody>
              </table>
            </div>
          </div>
        </motion.div>
      )}

      {/* Profile/Add Drawer */}
      <AnimatePresence>
        {showAdd && (
          <div className="fixed inset-0 z-[100] flex items-center justify-center p-6 bg-slate-900/60 backdrop-blur-lg overflow-y-auto">
             <motion.div initial={{ opacity: 0, scale: 0.9 }} animate={{ opacity: 1, scale: 1 }} exit={{ opacity: 0, scale: 0.9 }} className="bg-white w-full max-w-2xl rounded-[3rem] shadow-2xl p-10 relative">
                <button onClick={resetForm} className="absolute top-8 right-8 p-3 bg-slate-100 rounded-2xl">&times;</button>
                <h2 className="text-3xl font-black text-slate-900 tracking-tighter mb-10">{editingId ? 'Modify Client Profile' : 'Register New Client'}</h2>

                <div className="flex justify-center mb-10">
                    <label className="relative group cursor-pointer">
                       <div className="w-32 h-32 rounded-[2.5rem] bg-slate-50 border-2 border-dashed border-slate-200 flex flex-col items-center justify-center gap-2 group-hover:border-emerald-500 transition-all overflow-hidden">
                          {formData.image ? (
                             <img src={formData.image} className="w-full h-full object-cover" />
                          ) : (
                             <>
                                <Camera size={24} className="text-slate-300 group-hover:text-emerald-500" />
                                <span className="text-[9px] font-black uppercase text-slate-400 group-hover:text-emerald-500 tracking-widest">Portrait</span>
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

                <form onSubmit={handleSubmit} className="space-y-8">
                   <div className="grid grid-cols-2 gap-8">
                      <div className="space-y-2">
                        <label className="text-[10px] font-black uppercase text-slate-400 tracking-widest px-4">Full Business Name</label>
                        <input className="input-field h-16" value={formData.name} onChange={(e) => setFormData({...formData, name: e.target.value})} required />
                      </div>
                      <div className="space-y-2">
                         <label className="text-[10px] font-black uppercase text-slate-400 tracking-widest px-4">Direct Contact</label>
                         <input className="input-field h-16" value={formData.mobile} onChange={(e) => setFormData({...formData, mobile: e.target.value})} required />
                      </div>
                   </div>

                   <div className="space-y-2">
                      <label className="text-[10px] font-black uppercase text-slate-400 tracking-widest px-4">Operational Address</label>
                      <input className="input-field h-16" value={formData.address} onChange={(e) => setFormData({...formData, address: e.target.value})} />
                   </div>

                   <div className="grid grid-cols-2 gap-8">
                      <div className="space-y-2">
                         <label className="text-[10px] font-black uppercase text-slate-400 tracking-widest px-4">Tax ID (GST)</label>
                         <input className="input-field h-16 uppercase" value={formData.gstNumber} onChange={(e) => setFormData({...formData, gstNumber: e.target.value})} />
                      </div>
                      <div className="space-y-2">
                         <label className="text-[10px] font-black uppercase text-slate-400 tracking-widest px-4">Connectivity Email</label>
                         <input className="input-field h-16" value={formData.email} onChange={(e) => setFormData({...formData, email: e.target.value.toLowerCase()})} />
                      </div>
                   </div>

                   <div className="grid grid-cols-3 gap-8">
                      <div className="space-y-2">
                         <label className="text-[10px] font-black uppercase text-slate-400 tracking-widest px-4">District / Region</label>
                         <input className="input-field h-16" value={formData.district} placeholder="e.g. Varanasi" onChange={(e) => setFormData({...formData, district: e.target.value})} />
                      </div>
                      <div className="space-y-2">
                         <label className="text-[10px] font-black uppercase text-slate-400 tracking-widest px-4">Operational State</label>
                         <input className="input-field h-16" value={formData.state} placeholder="UP" onChange={(e) => setFormData({...formData, state: e.target.value})} />
                      </div>
                      <div className="space-y-2">
                         <label className="text-[10px] font-black uppercase text-slate-400 tracking-widest px-4">Country</label>
                         <input className="input-field h-16" value={formData.country} onChange={(e) => setFormData({...formData, country: e.target.value})} />
                      </div>
                   </div>



                   <button className="btn-primary w-full h-20 text-lg font-black uppercase tracking-widest shadow-2xl shadow-emerald-500/20 active:scale-95">
                      {editingId ? 'Update & Synchronize' : 'Finalize & Register'}
                   </button>
                </form>
             </motion.div>
          </div>
        )}
      </AnimatePresence>

    </motion.div>
  );
};

export default Customers;
