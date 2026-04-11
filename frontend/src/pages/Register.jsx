import { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { register as registerApi } from '../api/auth';
import { ArrowRight, ShieldCheck, Info } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';

const Register = () => {
  const [formData, setFormData] = useState({
    name: '', email: '', password: '', about: '', address: '', pinCode: '', gst: '', mobile: ''
  });
  const [errorDetails, setErrorDetails] = useState(null);
  const [loading, setLoading] = useState(false);
  const { loginShop } = useAuth();
  const navigate = useNavigate();

  const handleChange = (e) => {
    setFormData({ ...formData, [e.target.name]: e.target.value });
  };

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setErrorDetails(null);
    try {
      const data = await registerApi(formData);
      loginShop(data);
      navigate('/');
    } catch (err) {
      setErrorDetails({
        message: err.response?.data?.message || 'Registration failed.',
        error: err.response?.data?.error,
        details: err.response?.data?.details || []
      });
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-slate-50 flex items-center justify-center p-4 md:p-8 bg-[radial-gradient(circle_at_top_right,_#ecfdf5_10%,_transparent_40%),_radial-gradient(circle_at_bottom_left,_#eff6ff_10%,_transparent_40%)]">
      <motion.div 
        initial={{ opacity: 0, y: 10 }}
        animate={{ opacity: 1, y: 0 }}
        className="w-full max-w-5xl"
      >
        <div className="grid grid-cols-1 lg:grid-cols-12 glass rounded-[2.5rem] overflow-hidden shadow-2xl border-white/40 ring-1 ring-slate-200/50">
          
          <div className="lg:col-span-4 bg-emerald-700 p-8 md:p-12 text-white relative flex flex-col justify-between overflow-hidden">
            <div className="absolute top-0 right-0 w-64 h-64 bg-emerald-400/20 rounded-full -translate-y-1/2 translate-x-1/2 blur-3xl" />
            <div className="relative z-10">
              <h2 className="text-4xl font-extrabold font-sans tracking-tight mb-6 mt-12">Indian Gold</h2>
              <p className="text-emerald-100/70 leading-relaxed text-lg mb-12">Standard Enterprise Management Solution.</p>
              
              <div className="space-y-6">
                {['Direct MongoDB Sync', 'GST Ready Billing', 'Premium Analytics'].map((text, i) => (
                   <div key={i} className="flex items-center gap-4 text-sm font-semibold opacity-80">
                      <ShieldCheck size={18} /> {text}
                   </div>
                ))}
              </div>
            </div>
          </div>

          <div className="lg:col-span-8 bg-white/80 p-8 lg:p-14">
            <div className="flex flex-col md:flex-row md:items-center justify-between gap-4 mb-12">
               <div>
                  <h1 className="text-3xl font-black text-slate-900 tracking-tight">Create Shop Account</h1>
                  <p className="text-slate-400 font-bold text-sm mt-1">Professional business setup.</p>
               </div>
               <Link to="/login" className="text-emerald-700 bg-emerald-50 px-6 py-3 rounded-2xl text-xs font-black hover:bg-emerald-100 transition-all border border-emerald-100 uppercase tracking-widest leading-none">
                 Login
               </Link>
            </div>

            <form onSubmit={handleSubmit} className="space-y-8">
              <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                <input name="name" required className="input-field" placeholder="Full Business Name" onChange={handleChange} />
                <input name="mobile" required className="input-field" placeholder="Contact Mobile" onChange={handleChange} />
              </div>

              <input name="email" type="email" required className="input-field" placeholder="Work Email Address" onChange={handleChange} />

              <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
                <input name="password" type="password" required className="input-field" placeholder="Create Security Password" onChange={handleChange} />
                <input name="gst" className="input-field" placeholder="GST Number (Optional)" onChange={handleChange} />
              </div>

              <div className="grid grid-cols-1 md:grid-cols-3 gap-8">
                 <textarea name="address" required className="input-field md:col-span-2 min-h-[100px] py-4" placeholder="Full Business Address" onChange={handleChange} />
                 <input name="pinCode" required className="input-field" placeholder="Area Pin Code" onChange={handleChange} />
              </div>

              <AnimatePresence>
                {errorDetails && (
                  <motion.div initial={{ opacity: 0, y: -10 }} animate={{ opacity: 1, y: 0 }} className="p-5 bg-rose-50 border border-rose-100 rounded-2xl flex gap-3">
                    <Info className="text-rose-500 shrink-0" size={20} />
                    <div className="text-rose-800 font-bold text-xs uppercase">
                       <p className="font-black">{errorDetails.message}</p>
                       {errorDetails.details.map((d, i) => <p key={i} className="mt-1 font-bold opacity-80">{d}</p>)}
                    </div>
                  </motion.div>
                )}
              </AnimatePresence>

              <button type="submit" disabled={loading} className="btn-primary w-full h-[64px] text-lg flex items-center justify-center gap-3 active:scale-95 transition-transform">
                {loading ? <div className="w-6 h-6 border-4 border-white/30 border-t-white rounded-full animate-spin" /> : (
                  <>Finish Server Registration <ArrowRight size={22} /></>
                )}
              </button>
            </form>
          </div>
        </div>
      </motion.div>
    </div>
  );
};

export default Register;
