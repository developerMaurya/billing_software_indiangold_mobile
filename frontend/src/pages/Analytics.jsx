import { motion } from 'framer-motion';
import { TrendingUp, BarChart3, PieChart, Calendar } from 'lucide-react';

const Analytics = () => {
  return (
    <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }} className="space-y-10">
      <div className="flex items-center justify-between pb-8 border-b border-slate-100">
         <div>
            <h1 className="text-3xl font-black text-slate-900 tracking-tighter">Business Intelligence</h1>
            <p className="text-xs font-bold text-slate-400 uppercase tracking-widest mt-1 italic">Real-time Performance Metrics</p>
         </div>
         <button className="px-6 py-3 bg-white border border-slate-200 rounded-2xl text-[10px] font-black uppercase tracking-widest flex items-center gap-3">
           <Calendar size={16} className="text-emerald-500" /> Export Report
         </button>
      </div>

      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-3 gap-8">
         <div className="bg-emerald-950 p-10 rounded-[3rem] text-white space-y-6">
            <TrendingUp size={40} className="text-emerald-400" />
            <h3 className="text-4xl font-black tracking-tighter">₹1,24,590</h3>
            <p className="text-[10px] font-black uppercase tracking-widest text-emerald-500">Gross Revenue (30D)</p>
         </div>
         
         <div className="bg-white p-10 rounded-[3rem] border border-slate-100 shadow-sm space-y-6">
            <BarChart3 size={40} className="text-slate-200" />
            <h3 className="text-4xl font-black tracking-tighter text-slate-900">842</h3>
            <p className="text-[10px] font-black uppercase tracking-widest text-slate-400">Total Client Base</p>
         </div>

         <div className="bg-white p-10 rounded-[3rem] border border-slate-100 shadow-sm space-y-6">
            <PieChart size={40} className="text-slate-200" />
            <h3 className="text-4xl font-black tracking-tighter text-slate-900">12</h3>
            <p className="text-[10px] font-black uppercase tracking-widest text-slate-400">Low Stock Indicators</p>
         </div>
      </div>

      <div className="bg-white p-12 rounded-[3.5rem] border border-slate-100 shadow-sm text-center py-32">
         <TrendingUp size={64} className="mx-auto text-slate-100 mb-8" />
         <h4 className="text-2xl font-black text-slate-900 tracking-tight">Advanced Analytics Processing...</h4>
         <p className="text-sm font-bold text-slate-400 italic max-w-md mx-auto mt-4">We are currently synchronizing your transaction history to build precise growth charts.</p>
      </div>
    </motion.div>
  );
};

export default Analytics;
