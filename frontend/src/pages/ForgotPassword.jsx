import { useState } from 'react';
import { useNavigate, Link } from 'react-router-dom';
import { forgotPassword, resetPassword } from '../api/auth';
import { ShieldCheck, Mail, Phone, Lock, ArrowRight, CheckCircle2, ChevronLeft } from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';

const ForgotPassword = () => {
  const [step, setStep] = useState(1); // 1: Verify, 2: Reset
  const [formData, setFormData] = useState({ email: '', mobile: '', newPassword: '' });
  const [shopId, setShopId] = useState(null);
  const [loading, setLoading] = useState(false);
  const [error, setError] = useState('');
  const [success, setSuccess] = useState('');
  const navigate = useNavigate();

  const handleVerify = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    try {
      const data = await forgotPassword({ email: formData.email, mobile: formData.mobile });
      setShopId(data.shopId);
      setStep(2);
    } catch (err) {
      setError(err.response?.data?.message || 'Verification failed. Check your details.');
    } finally {
      setLoading(false);
    }
  };

  const handleReset = async (e) => {
    e.preventDefault();
    setLoading(true);
    setError('');
    try {
      await resetPassword({ shopId, newPassword: formData.newPassword });
      setSuccess('Your password has been changed successfully!');
      setTimeout(() => navigate('/'), 3000);
    } catch (err) {
      setError(err.response?.data?.message || 'Failed to reset password.');
    } finally {
      setLoading(false);
    }
  };

  return (
    <div className="min-h-screen bg-slate-50 flex items-center justify-center p-6 bg-[radial-gradient(circle_at_top_right,_#ecfdf5_10%,_transparent_25%),_radial-gradient(circle_at_bottom_left,_#eff6ff_10%,_transparent_25%)]">
      <motion.div initial={{ opacity: 0, y: 15 }} animate={{ opacity: 1, y: 0 }} className="w-full max-w-md">
        
        <Link to="/" className="inline-flex items-center gap-2 text-slate-400 hover:text-emerald-700 font-bold text-sm mb-8 transition-colors group">
           <ChevronLeft size={18} className="group-hover:-translate-x-1 transition-transform" />
           Back to Login
        </Link>

        <div className="text-center mb-8 flex flex-col items-center">
          <div className="w-16 h-16 rounded-2xl bg-emerald-600 text-white shadow-xl flex items-center justify-center mb-4">
             <Lock size={28} />
          </div>
          <h1 className="text-3xl font-black text-slate-900 tracking-tighter">Account Recovery</h1>
          <p className="text-slate-400 text-sm font-bold mt-1 uppercase tracking-widest leading-none">Security Center</p>
        </div>

        <div className="glass rounded-[2.5rem] p-10 shadow-2xl shadow-slate-200 border border-white/60">
           <AnimatePresence mode="wait">
             {success ? (
               <motion.div initial={{ opacity: 0, scale: 0.9 }} animate={{ opacity: 1, scale: 1 }} className="text-center py-6">
                  <div className="w-20 h-20 bg-emerald-100 text-emerald-600 rounded-full flex items-center justify-center mx-auto mb-6">
                     <CheckCircle2 size={40} />
                  </div>
                  <h3 className="text-xl font-black text-slate-900 mb-2">Success!</h3>
                  <p className="text-slate-500 font-medium leading-relaxed">{success}</p>
                  <p className="text-[10px] text-slate-300 font-black uppercase mt-8 tracking-[0.2em] animate-pulse">Redirecting to Login Portal...</p>
               </motion.div>
             ) : step === 1 ? (
               <motion.form key="step1" initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: -20 }} onSubmit={handleVerify} className="space-y-6">
                  <p className="text-sm font-bold text-slate-500 italic text-center mb-4">Verify your ownership using your registered email and mobile number.</p>
                  
                  <div className="space-y-2">
                     <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Work Email</label>
                     <input 
                       className="input-field" placeholder="admin@indiangold.com" required 
                       onChange={(e) => setFormData({...formData, email: e.target.value})}
                     />
                  </div>
                  <div className="space-y-2">
                     <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">Registered Mobile</label>
                     <input 
                       className="input-field" placeholder="+91 0000000000" required 
                       onChange={(e) => setFormData({...formData, mobile: e.target.value})}
                     />
                  </div>

                  {error && <div className="p-4 bg-rose-50 text-rose-600 text-xs font-black rounded-2xl border border-rose-100 uppercase">{error}</div>}
                  
                  <button type="submit" disabled={loading} className="btn-primary w-full h-[60px] flex items-center justify-center gap-3">
                    {loading ? <div className="w-6 h-6 border-4 border-white/25 border-t-white rounded-full animate-spin" /> : (
                      <>Verify Identity <ArrowRight size={20} /></>
                    )}
                  </button>
               </motion.form>
             ) : (
               <motion.form key="step2" initial={{ opacity: 0, x: 20 }} animate={{ opacity: 1, x: 0 }} exit={{ opacity: 0, x: -20 }} onSubmit={handleReset} className="space-y-6">
                  <div className="p-4 bg-emerald-50 rounded-2xl flex items-center gap-4 border border-emerald-100 mb-6">
                     <ShieldCheck className="text-emerald-600 shrink-0" />
                     <p className="text-xs font-bold text-emerald-800">Verification Successful. Enter your new security password below.</p>
                  </div>

                  <div className="space-y-2">
                     <label className="text-[10px] font-black text-slate-400 uppercase tracking-widest ml-1">New Password</label>
                     <input 
                       type="password" className="input-field grow" placeholder="••••••••" required 
                       onChange={(e) => setFormData({...formData, newPassword: e.target.value})}
                     />
                  </div>

                  {error && <div className="p-4 bg-rose-50 text-rose-600 text-xs font-black rounded-2xl border border-rose-100 uppercase">{error}</div>}

                  <button type="submit" disabled={loading} className="btn-primary w-full h-[60px] flex items-center justify-center gap-3">
                    {loading ? <div className="w-6 h-6 border-4 border-white/25 border-t-white rounded-full animate-spin" /> : (
                      <>Update Password <CheckCircle2 size={20} /></>
                    )}
                  </button>
               </motion.form>
             )}
           </AnimatePresence>
        </div>

        <p className="text-center text-[10px] text-slate-300 font-black uppercase tracking-[0.4em] mt-12 italic">
           Secured by Indian Gold Gateway
        </p>

      </motion.div>
    </div>
  )
}

export default ForgotPassword;
