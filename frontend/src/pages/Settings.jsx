import { useState, useEffect } from 'react';
import { motion } from 'framer-motion';
import { 
  Building2, 
  Mail, 
  MapPin, 
  Phone, 
  Globe, 
  ShieldCheck, 
  Save, 
  User,
  Settings as SettingsIcon,
  Briefcase,
  Lock,
  ArrowRight,
  Camera,
  Image as ImageIcon
} from 'lucide-react';
import { useAuth } from '../context/AuthContext';
import api from '../api';
import { uploadImageToCloudinary } from '../utils/cloudinary';


const Settings = () => {
  const { shop, updateShop } = useAuth();
  const [loading, setLoading] = useState(false);
  const [success, setSuccess] = useState(false);
  const [formData, setFormData] = useState({
    name: '',
    email: '',
    address: '',
    gst: '',
    about: '',
    pinCode: '',
    mobile: '',
    password: '',
    entityLegalName: '',
    logo: ''
  });
  const [uploading, setUploading] = useState(false);


  useEffect(() => {
    if (shop) {
      setFormData({
        name: shop.name || '',
        email: shop.email || '',
        address: shop.address || '',
        gst: shop.gst || '',
        about: shop.about || '',
        pinCode: shop.pinCode || '',
        mobile: shop.mobile || '',
        entityLegalName: shop.entityLegalName || '',
        logo: shop.logo || '',
        password: ''
      });

    }
  }, [shop]);

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setSuccess(false);
    try {
      const filteredData = { ...formData };
      if (!filteredData.password) delete filteredData.password;
      
      const response = await api.put('/auth/profile', filteredData);
      updateShop(response.data);
      setSuccess(true);
      setTimeout(() => setSuccess(false), 3000);
    } catch (error) {
      alert('Failed to update profile');
    } finally {
      setLoading(false);
    }
  };

  const handleLogoUpload = async (e) => {
    const file = e.target.files[0];
    if (!file) return;
    
    setUploading(true);
    const imageUrl = await uploadImageToCloudinary(file, "shop_branding");
    if (imageUrl) {
      setFormData({ ...formData, logo: imageUrl });
    }
    setUploading(false);
  };


  return (
    <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} className="max-w-5xl mx-auto space-y-10 pb-20">
      
      {/* Header */}
      <div className="flex items-center justify-between pb-8 border-b border-slate-100">
         <div>
            <h1 className="text-3xl font-black text-slate-900 tracking-tighter">Enterprise Settings</h1>
            <p className="text-xs font-bold text-slate-400 uppercase tracking-widest mt-1 italic">Master control for {shop?.name}</p>
         </div>
         <div className="bg-emerald-50 text-emerald-600 px-4 py-2 rounded-xl text-[10px] font-black uppercase tracking-widest border border-emerald-100 flex items-center gap-2">
            <ShieldCheck size={14} /> System Verified
         </div>
      </div>

      <form onSubmit={handleSubmit} className="grid grid-cols-1 lg:grid-cols-3 gap-10">
         
         {/* Sidebar Controls */}
         <div className="space-y-6">
            <div className="bg-white p-8 rounded-[2.5rem] border border-slate-100 shadow-sm space-y-4">
               <h3 className="text-sm font-black text-slate-800 uppercase tracking-tight mb-4">Configuration Profile</h3>
               <div className="space-y-1">
                  <div className="p-4 bg-emerald-600 text-white rounded-2xl flex items-center gap-3 cursor-pointer shadow-xl shadow-emerald-500/20">
                     <Building2 size={18} />
                     <span className="text-[10px] font-black uppercase tracking-widest font-secondary">Shop Credentials</span>
                  </div>
                  <div className="p-4 text-slate-400 hover:text-slate-600 rounded-2xl flex items-center gap-3 cursor-pointer transition-all">
                     <Lock size={18} />
                     <span className="text-[10px] font-black uppercase tracking-widest font-secondary">Security & Keys</span>
                  </div>
               </div>
            </div>

            <div className="bg-emerald-950 p-8 rounded-[2.5rem] text-white relative overflow-hidden group">
               <Globe className="absolute top-0 right-0 w-32 h-32 text-emerald-500/10 -translate-y-10 translate-x-10 group-hover:scale-125 transition-transform duration-1000" />
               <p className="text-[10px] font-black uppercase tracking-widest text-emerald-500 mb-2 leading-none">Status</p>
               <h4 className="text-xl font-black tracking-tight mb-6 flex items-center gap-2"><span className="w-2.5 h-2.5 bg-emerald-500 rounded-full animate-pulse" /> Live Server</h4>
               <p className="text-[9px] text-emerald-500/60 font-bold leading-relaxed italic">All changes are synchronized across your enterprise cloud instances in real-time.</p>
            </div>
         </div>

          {/* Main Input Form */}
          <div className="lg:col-span-2 space-y-8">
             <div className="bg-white p-10 rounded-[3rem] border border-slate-100 shadow-sm space-y-10">
                
                {/* Logo & Branding */}
                <div className="flex flex-col md:flex-row items-center gap-10 pb-10 border-b border-slate-50">
                    <label className="relative group cursor-pointer">
                        <div className="w-40 h-40 rounded-[3rem] bg-slate-50 border-2 border-dashed border-slate-200 flex flex-col items-center justify-center gap-2 group-hover:border-emerald-500 transition-all overflow-hidden shadow-xl">
                           {formData.logo ? (
                              <img src={formData.logo} className="w-full h-full object-cover" />
                           ) : (
                              <>
                                 <Camera size={32} className="text-slate-300 group-hover:text-emerald-500" />
                                 <span className="text-[10px] font-black uppercase text-slate-400 group-hover:text-emerald-500 tracking-[0.2em]">Upload Logo</span>
                              </>
                           )}
                           {uploading && (
                              <div className="absolute inset-0 bg-white/80 flex items-center justify-center">
                                 <div className="w-8 h-8 border-2 border-emerald-500 border-t-transparent rounded-full animate-spin" />
                              </div>
                           )}
                        </div>
                        <input type="file" className="hidden" accept="image/*" onChange={handleLogoUpload} />
                    </label>
                    <div className="flex-1 space-y-2">
                       <h4 className="text-xl font-black text-slate-900 tracking-tight">Corporate Branding</h4>
                       <p className="text-xs font-medium text-slate-400 leading-relaxed italic">Upload your high-resolution logo. This will be used for cloud branding and on all generated enterprise documents (PDF/Invoices).</p>
                    </div>
                </div>

                {/* Identity Section */}

               <div className="space-y-8">
                  <div className="flex items-center gap-3 text-emerald-500">
                     <Briefcase size={20} />
                     <h4 className="text-xs font-black uppercase tracking-[0.3em]">Corporate Identity</h4>
                  </div>
                  
                  <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                     <div className="space-y-2">
                        <label className="text-[10px] font-black uppercase text-slate-400 tracking-widest px-4">Entity Legal Name</label>
                        <input 
                           className="input-field h-14" 
                           placeholder="e.g. Indian Gold Pvt Ltd"
                           value={formData.entityLegalName} 
                           onChange={(e) => setFormData({...formData, entityLegalName: e.target.value})}
                        />
                     </div>
                     <div className="space-y-2">
                        <label className="text-[10px] font-black uppercase text-slate-400 tracking-widest px-4">Public Trading Name</label>
                        <input 
                           className="input-field h-14" 
                           value={formData.name} 
                           onChange={(e) => setFormData({...formData, name: e.target.value})}
                           required 
                        />
                     </div>
                  </div>
                   <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                      <div className="space-y-2">
                         <label className="text-[10px] font-black uppercase text-slate-400 tracking-widest px-4">Tax Registration (GST)</label>
                         <input 
                            className="input-field h-14 uppercase" 
                            value={formData.gst} 
                            onChange={(e) => setFormData({...formData, gst: e.target.value})}
                         />
                      </div>
                      <div className="space-y-2 invisible md:visible">
                      </div>
                   </div>

                   <div className="space-y-2">

                     <label className="text-[10px] font-black uppercase text-slate-400 tracking-widest px-4">Core Mission / Description</label>
                     <textarea 
                        className="input-field min-h-[100px] py-4" 
                        value={formData.about} 
                        onChange={(e) => setFormData({...formData, about: e.target.value})}
                        placeholder="Detail your business operations..."
                     />
                  </div>
               </div>

               {/* Logistics Section */}
               <div className="space-y-8 pt-10 border-t border-slate-50">
                  <div className="flex items-center gap-3 text-emerald-500">
                     <MapPin size={20} />
                     <h4 className="text-xs font-black uppercase tracking-[0.3em]">Logistics & Contact</h4>
                  </div>

                  <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                     <div className="space-y-2">
                        <label className="text-[10px] font-black uppercase text-slate-400 tracking-widest px-4">Contact Phone</label>
                        <input 
                           className="input-field h-14" 
                           value={formData.mobile} 
                           onChange={(e) => setFormData({...formData, mobile: e.target.value})}
                        />
                     </div>
                     <div className="space-y-2">
                        <label className="text-[10px] font-black uppercase text-slate-400 tracking-widest px-4">Cloud Primary Email</label>
                        <input 
                           className="input-field h-14" 
                           value={formData.email} 
                           onChange={(e) => setFormData({...formData, email: e.target.value})}
                           required 
                        />
                     </div>
                  </div>

                  <div className="grid grid-cols-1 md:grid-cols-4 gap-8">
                     <div className="md:col-span-3 space-y-2">
                        <label className="text-[10px] font-black uppercase text-slate-400 tracking-widest px-4">Headquarters Address</label>
                        <input 
                           className="input-field h-14" 
                           value={formData.address} 
                           onChange={(e) => setFormData({...formData, address: e.target.value})}
                        />
                     </div>
                     <div className="space-y-2">
                        <label className="text-[10px] font-black uppercase text-slate-400 tracking-widest px-4">PIN Code</label>
                        <input 
                           className="input-field h-14" 
                           value={formData.pinCode} 
                           onChange={(e) => setFormData({...formData, pinCode: e.target.value})}
                        />
                     </div>
                  </div>
               </div>

               {/* Security Section */}
               <div className="space-y-8 pt-10 border-t border-slate-50">
                  <div className="flex items-center gap-3 text-emerald-500">
                     <Lock size={20} />
                     <h4 className="text-xs font-black uppercase tracking-[0.3em]">Enhanced Security</h4>
                  </div>
                  <div className="space-y-2">
                     <label className="text-[10px] font-black uppercase text-slate-400 tracking-widest px-4">Change Master Password</label>
                     <input 
                        type="password"
                        className="input-field h-14" 
                        placeholder="Leave blank to keep current"
                        value={formData.password} 
                        onChange={(e) => setFormData({...formData, password: e.target.value})}
                     />
                  </div>
               </div>

               {/* Footer Action */}
               <div className="pt-10 flex items-center justify-between">
                  <div className="group">
                     {success && (
                        <motion.p initial={{ opacity: 0, x: -10 }} animate={{ opacity: 1, x: 0 }} className="text-emerald-500 font-black text-[10px] uppercase tracking-widest flex items-center gap-2">
                           <ShieldCheck size={16} /> Configuration Synchronized Successfully
                        </motion.p>
                     )}
                  </div>
                  <button 
                     disabled={loading}
                     className="btn-primary min-w-[240px] h-16 text-xs font-black uppercase tracking-widest flex items-center justify-center gap-3 shadow-2xl shadow-emerald-500/20 active:scale-95 disabled:opacity-50"
                  >
                     {loading ? 'Synchronizing...' : 'Save Configuration'}
                     {!loading && <ArrowRight size={18} />}
                  </button>
               </div>
            </div>
         </div>
      </form>
    </motion.div>
  );
};

export default Settings;
