import { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { login as loginApi } from '../api/auth';
import { ShieldCheck, ArrowRight, Lock, Server, Globe } from 'lucide-react';
import { motion } from 'framer-motion';

const Login = () => {
  const [email, setEmail] = useState('');
  const [password, setPassword] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(false);
  const { loginShop } = useAuth();
  const navigate = useNavigate();

  const handleSubmit = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    try {
      const data = await loginApi({ email, password });
      loginShop(data);
      navigate('/dashboard');
    } catch (err) {
      setError(err.response?.data?.message || 'Invalid Credentials. Please try again.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-slate-50 flex items-center justify-center p-6 bg-[radial-gradient(circle_at_top_right,_#ecfdf5_0.5%,_transparent_25%),_radial-gradient(circle_at_bottom_left,_#eff6ff_0.5%,_transparent_25%)]">
      <motion.div initial={{ opacity: 0, scale: 0.95 }} animate={{ opacity: 1, scale: 1 }} className="w-full max-w-lg">
        
        {/* Branding & Logo Header */}
        <div className="text-center mb-10 flex flex-col items-center">
          <div className="w-20 h-20 rounded-[2rem] bg-gradient-to-tr from-emerald-600 to-emerald-400 flex items-center justify-center text-white shadow-2xl shadow-emerald-500/30 mb-6 group cursor-pointer hover:rotate-6 transition-all duration-500">
            <ShieldCheck size={42} strokeWidth={1.5} />
          </div>
          <h1 className="text-4xl font-black text-slate-900 tracking-tighter leading-none">INDIAN GOLD</h1>
          <p className="text-slate-400 mt-2 font-bold uppercase tracking-[0.3em] flex items-center gap-2 text-[11px] leading-none mb-1">
             <Globe size={11} className="text-emerald-500" />
             Enterprise Billing Portal
          </p>
        </div>

        {/* Login Container */}
        <div className="glass rounded-[3rem] p-12 shadow-2xl shadow-slate-200/50 border border-white/60 relative overflow-hidden">
           <div className="absolute top-0 right-0 w-32 h-32 bg-emerald-500/5 rounded-full -translate-y-12 translate-x-12" />
           
           <div className="relative z-10">
              <h2 className="text-2xl font-black text-slate-900 tracking-tight flex items-center gap-2 mb-8">
                 Admin Sign In 
                 <span className="text-emerald-500 text-sm animate-pulse">●</span>
              </h2>

              <form onSubmit={handleSubmit} className="space-y-8">
                <div className="group relative">
                  <input 
                    type="email" 
                    className="input-field border-slate-100 bg-slate-50/50 focus:bg-white text-lg h-[64px]"
                    placeholder="Enter Business Email"
                    value={email}
                    onChange={(e) => setEmail(e.target.value)}
                    required
                  />
                  <div className="absolute right-4 top-1/2 -translate-y-1/2 opacity-20 pointer-events-none group-focus-within:opacity-100 transition-opacity">
                     <span className="text-[10px] font-black text-emerald-600 font-sans tracking-widest uppercase mb-1 block text-right">Required</span>
                  </div>
                </div>

                <div className="group relative">
                  <div className="flex items-center justify-between mb-2">
                     <span className="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Password</span>
                     <Link to="/forgot-password" size={12} className="text-[11px] font-bold text-emerald-600 hover:text-emerald-700 transition-colors uppercase tracking-tight">Forgot password?</Link>
                  </div>
                  <input 
                    type="password" 
                    className="input-field border-slate-100 bg-slate-50/50 focus:bg-white text-lg h-[64px]"
                    placeholder="Security Password"
                    value={password}
                    onChange={(e) => setPassword(e.target.value)}
                    required
                  />
                </div>

                {error && (
                  <motion.div initial={{ opacity: 0, x: -10 }} animate={{ opacity: 1, x: 0 }} className="p-4 bg-rose-50 border border-rose-100 rounded-2xl flex items-center gap-3">
                     <Info className="text-rose-500 shrink-0" size={18} />
                     <p className="text-rose-700 text-xs font-black uppercase tracking-widest leading-none">{error}</p>
                  </motion.div>
                )}

                <button type="submit" disabled={loading} className="btn-primary w-full h-[68px] text-lg flex items-center justify-center gap-3 font-black uppercase tracking-[0.1em] shadow-2xl hover:scale-[1.02] active:scale-[0.98]">
                  {loading ? <div className="w-6 h-6 border-4 border-white/30 border-t-white rounded-full animate-spin" /> : (
                    <>Establish Connection <ArrowRight size={22} /></>
                  )}
                </button>
              </form>

              {/* Secure Badge Footer */}
              <div className="mt-12 flex items-center justify-between opacity-40">
                 <div className="flex items-center gap-2">
                    <Lock size={12} className="text-emerald-600" />
                    <span className="text-[10px] font-black uppercase tracking-widest">End-to-end Encrypted</span>
                 </div>
                 <div className="flex items-center gap-2">
                    <Server size={12} className="text-emerald-600" />
                    <span className="text-[10px] font-black uppercase tracking-widest">MongoDB Isolated Hub</span>
                 </div>
              </div>
           </div>
        </div>

        {/* Footer Link */}
        <div className="mt-10 text-center">
           <Link to="/register" className="text-slate-400 hover:text-emerald-600 transition-all font-bold text-sm tracking-tight flex items-center justify-center gap-2">
              New Business Enterprise? <span className="text-emerald-700 font-extrabold underline-offset-4 hover:underline">Register New Shop Profile</span>
           </Link>
        </div>
      </motion.div>
    </div>
  );
};

export default Login;
