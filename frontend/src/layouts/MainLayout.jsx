import { useState } from 'react';
import { Link, useLocation, useNavigate } from 'react-router-dom';
import { useAuth } from '../context/AuthContext';
import { 
  LayoutDashboard, 
  Package, 
  Users, 
  ShoppingCart, 
  BarChart3, 
  Settings, 
  LogOut, 
  Menu, 
  X,
  Bell,
  Search,
  Store,
  ChevronRight,
  ShieldCheck,
  FileText,
  AlertTriangle,
  Camera,
  ArrowLeft
} from 'lucide-react';
import { motion, AnimatePresence } from 'framer-motion';

const SidebarItem = ({ icon: Icon, label, path, active, collapsed }) => (
  <Link to={path}>
    <motion.div 
      whileHover={{ x: 4 }}
      className={`flex items-center px-4 py-3.5 rounded-2xl transition-all duration-200 group mb-2 cursor-pointer
        ${active 
          ? 'bg-emerald-600 text-white shadow-lg shadow-emerald-600/20' 
          : 'text-slate-500 hover:bg-slate-100/80 hover:text-slate-900'}`
      }
    >
      <Icon size={20} className={`${active ? 'text-white' : 'group-hover:text-emerald-500'}`} />
      {!collapsed && (
        <span className="ml-3 font-semibold text-xs tracking-tight">{label}</span>
      )}
      {active && !collapsed && (
        <motion.div layoutId="active-pill" className="ml-auto">
          <ChevronRight size={16} />
        </motion.div>
      )}
    </motion.div>
  </Link>
);

const MainLayout = ({ children }) => {
  const [collapsed, setCollapsed] = useState(false);
  const [mobileOpen, setMobileOpen] = useState(false);
  const { shop, logoutShop } = useAuth();
  const location = useLocation();
  const navigate = useNavigate();

  const menuItems = [
    { icon: LayoutDashboard, label: 'Dashboard', path: '/dashboard' },
    { icon: Package, label: 'Products', path: '/products' },
    { icon: Users, label: 'Customers', path: '/customers' },
    { icon: ShoppingCart, label: 'Sales/Billing', path: '/sales' },
    { icon: FileText, label: 'Bill History', path: '/bill-history' },
    { icon: BarChart3, label: 'Analytics', path: '/analytics' },
    { icon: Settings, label: 'Settings', path: '/settings' },
  ];

  const handleLogout = () => {
    logoutShop();
    navigate('/');
  };

  return (
    <div className="flex min-h-screen bg-slate-50 overflow-hidden">
      {/* Sidebar - Desktop */}
      <motion.aside 
        animate={{ width: collapsed ? 88 : 280 }}
        className="hidden lg:flex flex-col bg-white border-r border-slate-100 h-screen sticky top-0 z-20 transition-all duration-300 shadow-sm"
      >
        <div className="p-6 flex items-center gap-3">
          <div className="w-10 h-10 bg-emerald-600 rounded-xl flex items-center justify-center text-white shrink-0 shadow-lg shadow-emerald-600/20">
            <Store size={20} />
          </div>
          {!collapsed && (
            <motion.div initial={{ opacity: 0 }} animate={{ opacity: 1 }}>
              <h1 className="font-bold text-lg text-slate-800 tracking-tighter">INDIAN GOLD</h1>
              <p className="text-[10px] uppercase font-bold text-slate-400 tracking-[0.2em] -mt-1 leading-none">Management</p>
            </motion.div>
          )}
        </div>

        <nav className="flex-1 px-4 mt-4 overflow-y-auto no-scrollbar">
          {menuItems.map((item) => (
            <SidebarItem 
              key={item.path} 
              {...item} 
              active={location.pathname === item.path}
              collapsed={collapsed}
            />
          ))}
        </nav>

        <div className="p-4 border-t border-slate-100 mb-4 mx-4 bg-slate-50/50 rounded-2xl mt-auto">
          {!collapsed && (
            <div className="flex items-center gap-3 mb-4 p-2">
               <div className="w-10 h-10 rounded-xl bg-slate-200 border-2 border-white shadow-sm flex items-center justify-center text-slate-500 font-bold uppercase overflow-hidden italic">
                  {shop?.logo ? (
                      <img src={shop.logo} className="w-full h-full object-cover" />
                   ) : (
                      shop?.name?.charAt(0) || 'S'
                   )}
               </div>
               <div className="overflow-hidden">
                 <p className="text-sm font-bold text-slate-800 truncate leading-none mb-1">{shop?.name || 'My Shop'}</p>
                 <p className="text-[10px] text-slate-400 font-medium truncate uppercase tracking-widest leading-none">Enterprise Plan</p>
               </div>
            </div>
          )}
          <button 
            onClick={handleLogout}
            className={`w-full flex items-center px-4 py-3 text-slate-500 hover:text-emerald-600 hover:bg-emerald-50 rounded-xl transition-all duration-200 font-bold text-sm
              ${collapsed ? 'justify-center' : 'justify-start'}`}
          >
            <LogOut size={20} />
            {!collapsed && <span className="ml-3 italic">Logout</span>}
          </button>
        </div>
      </motion.aside>

      {/* Main Content */}
      <main className="flex-1 flex flex-col min-w-0 max-h-screen overflow-hidden">
        {/* Navbar */}
        <header className="h-20 bg-white/80 backdrop-blur-md border-b border-slate-100 flex items-center justify-between px-6 sticky top-0 z-10">
          <div className="flex items-center gap-4">
            <button 
              onClick={() => setCollapsed(!collapsed)}
              className="p-2 hover:bg-slate-100 rounded-lg text-slate-500 hidden lg:block transition-colors"
            >
              {collapsed ? <Menu size={20} /> : <X size={20} />}
            </button>
            <button 
              onClick={() => setMobileOpen(true)}
              className="p-2 hover:bg-slate-100 rounded-lg text-slate-500 lg:hidden"
            >
              <Menu size={20} />
            </button>
            
            <div className="relative hidden md:block group">
              <Search className="absolute left-3 top-1/2 -translate-y-1/2 text-slate-400 group-focus-within:text-emerald-500 transition-colors" size={18} />
              <input 
                type="text" 
                placeholder="Search inventory, orders..." 
                className="bg-slate-50 border-none rounded-xl pl-10 pr-4 py-2 w-72 text-sm outline-none focus:ring-2 focus:ring-emerald-500/10 focus:bg-white transition-all shadow-inner"
              />
            </div>
          </div>

          <div className="flex items-center gap-2">
            <button className="p-2.5 text-slate-400 hover:text-emerald-500 hover:bg-emerald-50 rounded-xl transition-all relative shadow-sm">
              <Bell size={20} />
              <span className="absolute top-2.5 right-2.5 w-2 h-2 bg-emerald-500 rounded-full border-2 border-white" />
            </button>
            <div className="w-px h-6 bg-slate-100 mx-2" />
            <div className="flex items-center gap-3 pl-2">
               <div className="text-right hidden sm:block">
                  <p className="text-sm font-bold text-slate-800 leading-none mb-1">Session Active</p>
                  <p className="text-[10px] text-emerald-500 font-bold uppercase tracking-widest flex items-center justify-end gap-1 leading-none italic">
                    <ShieldCheck size={10} /> Verified
                  </p>
               </div>
               <div className="w-10 h-10 rounded-2xl bg-gradient-to-tr from-emerald-500 to-emerald-600 shadow-md shadow-emerald-500/20 border-2 border-white flex items-center justify-center text-white text-sm font-bold overflow-hidden italic">
                  {shop?.logo ? (
                      <img src={shop.logo} className="w-full h-full object-cover shadow-inner" />
                   ) : (
                      shop?.name?.charAt(0) || 'A'
                   )}
               </div>
            </div>
          </div>
        </header>

        {/* Dynamic Page Content */}
        <section className="flex-1 overflow-y-auto p-6 md:p-8 space-y-8 bg-slate-50/30 custom-scrollbar pb-32">
          {children}
        </section>
      </main>

      {/* Mobile Drawer */}
      <AnimatePresence>
        {mobileOpen && (
          <>
            <motion.div 
              initial={{ opacity: 0 }}
              animate={{ opacity: 1 }}
              exit={{ opacity: 0 }}
              onClick={() => setMobileOpen(false)}
              className="fixed inset-0 bg-slate-900/60 backdrop-blur-[2px] z-[998] lg:hidden"
            />
            <motion.aside 
              initial={{ x: -280 }}
              animate={{ x: 0 }}
              exit={{ x: -280 }}
              className="fixed top-0 bottom-0 left-0 w-72 bg-white z-[999] lg:hidden p-6 flex flex-col shadow-2xl"
            >
              <div className="flex items-center justify-between mb-8">
                 <div className="flex items-center gap-2">
                    <div className="w-8 h-8 bg-emerald-600 rounded-lg flex items-center justify-center text-white">
                      <Store size={16} />
                    </div>
                    <h1 className="font-bold text-slate-800 tracking-tighter">INDIAN GOLD</h1>
                 </div>
                 <button onClick={() => setMobileOpen(false)} className="p-2 hover:bg-slate-100 rounded-xl">
                   <X size={20} />
                 </button>
              </div>

              <nav className="flex-1 overflow-y-auto no-scrollbar">
                {menuItems.map((item) => (
                  <SidebarItem 
                    key={item.path} 
                    {...item} 
                    active={location.pathname === item.path}
                    collapsed={false}
                  />
                ))}
              </nav>

              <button 
                onClick={handleLogout}
                className="w-full flex items-center px-4 py-3.5 text-slate-500 hover:text-emerald-600 hover:bg-emerald-50 rounded-2xl transition-all font-bold text-sm mb-4"
              >
                <LogOut size={20} />
                <span className="ml-3 italic">Logout</span>
              </button>
            </motion.aside>
          </>
        )}
      </AnimatePresence>
    </div>
  );
};

export default MainLayout;
