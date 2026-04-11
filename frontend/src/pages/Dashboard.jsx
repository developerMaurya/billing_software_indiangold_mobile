import { motion } from 'framer-motion';
import { 
  TrendingUp, 
  DollarSign, 
  Users, 
  ShoppingCart, 
  Package,
  Calendar,
  ChevronRight,
  ArrowUpRight,
  Plus,
  Activity,
  CreditCard
} from 'lucide-react';
import { useAuth } from '../context/AuthContext';

const StatCard = ({ icon: Icon, label, value, trend, color, trendUp }) => (
  <motion.div 
    whileHover={{ y: -8, scale: 1.02 }}
    className="p-6 md:p-8 bg-white rounded-[2rem] md:rounded-[2.5rem] border border-slate-100 shadow-sm hover:shadow-2xl hover:shadow-emerald-500/10 transition-all duration-500 relative overflow-hidden group cursor-pointer"
  >
    <div className={`absolute top-0 right-0 w-32 h-32 bg-${color}-500/5 rounded-full -translate-y-12 translate-x-12 group-hover:scale-125 transition-transform duration-700`} />
    
    <div className="flex items-center justify-between mb-4 md:mb-6 relative z-10">
      <div className={`p-3 md:p-4 rounded-2xl md:rounded-3xl bg-${color}-50 text-${color}-600 group-hover:bg-${color}-600 group-hover:text-white transition-all duration-500 shadow-sm`}>
        <Icon size={24} className="md:w-7 md:h-7" />
      </div>
      <div className={`flex items-center gap-1.5 px-3 py-1 rounded-full text-[9px] md:text-xs font-black tracking-tighter ${trendUp ? 'bg-emerald-50 text-emerald-600' : 'bg-rose-50 text-rose-600'}`}>
        <Activity size={12} className="md:w-3.5 md:h-3.5" />
        {trend}
      </div>
    </div>
    
    <div className="relative z-10">
      <p className="text-[10px] md:text-[11px] font-black text-slate-400 uppercase tracking-[0.2em] mb-2 leading-none">{label}</p>
      <h3 className="text-2xl md:text-3xl font-black text-slate-900 tracking-tighter">{value}</h3>
    </div>
  </motion.div>
);

const TransactionRow = ({ name, date, amount, status }) => (
  <div className="flex items-center justify-between p-5 hover:bg-emerald-50/50 transition-all rounded-[2rem] group cursor-pointer border border-transparent hover:border-emerald-100/50">
    <div className="flex items-center gap-5">
      <div className="w-12 h-12 bg-slate-100 rounded-2xl flex items-center justify-center text-slate-500 group-hover:bg-white group-hover:shadow-md group-hover:text-emerald-500 transition-all duration-300">
         <Users size={22} />
      </div>
      <div>
        <p className="text-sm font-black text-slate-900 tracking-tight leading-none mb-1.5">{name}</p>
        <p className="text-[10px] text-slate-400 font-bold uppercase tracking-widest leading-none italic">{date}</p>
      </div>
    </div>
    <div className="text-right">
      <p className="text-sm font-black text-slate-900 leading-none mb-1.5 tracking-tight flex items-center justify-end gap-1">
        ₹{amount}
      </p>
      <span className={`text-[9px] font-black px-3 py-1 rounded-full uppercase tracking-widest ${status === 'Paid' ? 'bg-emerald-100 text-emerald-700' : 'bg-amber-100 text-amber-700'}`}>
        {status}
      </span>
    </div>
  </div>
);

const Dashboard = () => {
  const { shop } = useAuth();
  
  return (
    <motion.div initial={{ opacity: 0, y: 20 }} animate={{ opacity: 1, y: 0 }} className="max-w-[1600px] mx-auto space-y-12 pb-24">
      
      {/* Header */}
      <div className="flex flex-col md:flex-row md:items-end justify-between gap-8 pb-6 border-b border-slate-100">
        <div className="space-y-2">
           <h1 className="text-3xl md:text-4xl font-black text-slate-900 tracking-tighter">Enterprise Overview</h1>
           <p className="text-slate-400 font-bold text-xs md:text-sm flex items-center gap-2 italic">
              <span className="w-2 h-2 rounded-full bg-emerald-500 animate-pulse" />
              Connected as {shop?.name} • Live Session Operational
           </p>
        </div>
        <div className="flex flex-wrap items-center gap-3 md:gap-4">
           <button className="flex-1 md:flex-none px-4 md:px-6 py-3 md:py-3.5 bg-white border border-slate-200 rounded-2xl text-slate-600 text-[10px] md:text-xs font-black shadow-sm hover:shadow-md transition-all flex items-center justify-center gap-2 md:gap-3">
             <Calendar size={18} className="text-emerald-500" />
             Weekly Reports
           </button>
           <button className="flex-1 md:flex-none btn-primary flex items-center justify-center gap-2 md:gap-3 shadow-2xl py-3 md:py-3.5 text-[10px] md:text-xs uppercase tracking-widest font-black">
             <Plus size={20} className="stroke-[3px]" />
             Quick Invoice
           </button>
        </div>
      </div>

      {/* Main Stats */}
      <div className="grid grid-cols-1 md:grid-cols-2 lg:grid-cols-4 gap-8">
        <StatCard icon={DollarSign} label="Monthly Revenue" value="₹1,24,590" trend="+12% 🚀" color="emerald" trendUp={true} />
        <StatCard icon={ShoppingCart} label="Active Orders" value="48" trend="-2.4%" color="sky" trendUp={false} />
        <StatCard icon={Users} label="Premium Users" value="842" trend="+18% 🔥" color="indigo" trendUp={true} />
        <StatCard icon={Package} label="Low Stock Alert" value="12" trend="Critical" color="amber" trendUp={false} />
      </div>

      {/* Center Grid */}
      <div className="grid grid-cols-1 lg:grid-cols-12 gap-10">
        
        {/* Left Area: Graph Mockup */}
        <div className="lg:col-span-8 flex flex-col gap-8">
          <div className="p-10 bg-white rounded-[3rem] border border-slate-100 shadow-sm relative overflow-hidden h-[480px]">
             <div className="flex items-center justify-between mb-12">
               <div>
                  <h3 className="text-2xl font-black text-slate-900 tracking-tighter">Growth Analytics</h3>
                  <p className="text-[11px] font-black text-slate-400 uppercase tracking-[0.2em] mt-1">Daily interaction tracking</p>
               </div>
               <div className="flex items-center gap-2 p-1 bg-slate-50 rounded-xl border border-slate-100">
                  <button className="px-4 py-1.5 bg-white shadow-sm rounded-lg text-xs font-black text-emerald-600 uppercase">Sales</button>
                  <button className="px-4 py-1.5 text-xs font-black text-slate-400 uppercase hover:text-slate-600 transition-colors">Users</button>
               </div>
             </div>
             
             {/* Dynamic Bar Mockup */}
             <div className="absolute bottom-14 left-10 right-10 top-36 flex items-end justify-between gap-3">
                {[55, 75, 45, 90, 80, 100, 85, 95, 60, 110, 105, 120].map((h, i) => (
                  <div key={i} className="flex-1 group relative h-full flex flex-col justify-end">
                    <motion.div 
                      initial={{ height: 0 }}
                      animate={{ height: `${(h/120)*100}%` }}
                      className={`w-full rounded-2xl transition-all duration-500 cursor-help
                        ${i === 11 ? 'bg-gradient-to-t from-emerald-700 to-emerald-400 shadow-2xl shadow-emerald-500/40' : 'bg-slate-100/80 group-hover:bg-emerald-100'}
                      `}
                    />
                    <span className="text-[9px] font-black text-slate-300 mt-6 text-center uppercase tracking-widest">{['J','F','M','A','M','J','J','A','S','O','N','D'][i]}</span>
                  </div>
                ))}
             </div>
          </div>

          <div className="grid grid-cols-1 md:grid-cols-2 gap-8">
             <div className="p-8 bg-emerald-950 rounded-[2.5rem] text-white shadow-2xl shadow-emerald-900/10 relative overflow-hidden group">
                <CreditCard className="absolute top-8 right-8 text-emerald-500/20 w-16 h-16 group-hover:scale-125 transition-transform duration-700" />
                <h4 className="text-[10px] font-black uppercase tracking-[0.3em] opacity-40 mb-2">Wallet Balance</h4>
                <p className="text-4xl font-black tracking-tighter">₹84,290.00</p>
                <div className="mt-8 flex items-center gap-3">
                   <div className="px-3 py-1 bg-emerald-500/20 border border-emerald-500/20 rounded-lg text-[10px] font-black uppercase text-emerald-400 tracking-widest">+ ₹12k today</div>
                </div>
             </div>
             <div className="p-8 bg-white border border-slate-100 rounded-[2.5rem] relative group hover:shadow-xl transition-all duration-500">
                <TrendingUp className="absolute top-8 right-8 text-emerald-100 w-16 h-16" />
                <h4 className="text-[10px] font-black uppercase tracking-[0.3em] text-slate-400 mb-2">Network Growth</h4>
                <p className="text-4xl font-black tracking-tighter text-slate-900">+145%</p>
                <p className="mt-4 text-xs font-bold text-slate-400 italic leading-relaxed">System performance is exceeding monthly benchmarks.</p>
             </div>
          </div>
        </div>

        {/* Recent Transaction Column - Clean & Modern */}
        <div className="lg:col-span-4 p-10 bg-white rounded-[3rem] border border-slate-100 shadow-sm flex flex-col min-h-[600px]">
          <div className="flex items-center justify-between mb-10">
            <div>
              <h3 className="text-2xl font-black text-slate-900 tracking-tighter leading-none mb-1">Recent Activity</h3>
              <p className="text-[10px] font-black text-slate-400 uppercase tracking-widest italic">Latest 7 transactions</p>
            </div>
            <button className="w-10 h-10 bg-emerald-50 rounded-2xl flex items-center justify-center text-emerald-600 hover:bg-emerald-600 hover:text-white transition-all shadow-sm">
               <ChevronRight size={20} />
            </button>
          </div>
          
          <div className="flex-1 space-y-3 overflow-y-auto pr-2 -mr-3 no-scrollbar custom-scrollbar">
            <TransactionRow name="Deepak Maurya" date="Mar 29, 2026 • 12:45 PM" amount="1,450" status="Paid" />
            <TransactionRow name="Rajesh Kumar" date="Mar 29, 2026 • 11:30 AM" amount="4,200" status="Paid" />
            <TransactionRow name="Amit Sharma" date="Mar 29, 2026 • 10:15 AM" amount="890" status="Pending" />
            <TransactionRow name="Sunil Gupta" date="Mar 28, 2026 • 05:20 PM" amount="12,400" status="Paid" />
            <TransactionRow name="Vikas Yadav" date="Mar 28, 2026 • 04:00 PM" amount="2,150" status="Paid" />
            <TransactionRow name="Karan Singh" date="Mar 28, 2026 • 02:30 PM" amount="550" status="Pending" />
            <TransactionRow name="Aryan Pratap" date="Mar 28, 2026 • 01:10 PM" amount="1,800" status="Paid" />
          </div>

          <div className="mt-10 p-5 bg-emerald-50 rounded-3xl border border-emerald-100 border-dashed text-center">
             <p className="text-[10px] font-black text-emerald-700 uppercase tracking-[0.2em] italic">System Audit Complete 100% Secure</p>
          </div>
        </div>

      </div>
    </motion.div>
  );
};

export default Dashboard;
