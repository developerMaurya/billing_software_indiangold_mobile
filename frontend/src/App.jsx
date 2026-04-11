import { BrowserRouter as Router, Routes, Route, Navigate } from 'react-router-dom';
import { AuthProvider, useAuth } from './context/AuthContext';
import Login from './pages/Login';
import Register from './pages/Register';
import ForgotPassword from './pages/ForgotPassword';
import Dashboard from './pages/Dashboard';
import Products from './pages/Products';
import Customers from './pages/Customers';
import Sales from './pages/Sales';
import Analytics from './pages/Analytics';
import BillHistory from './pages/BillHistory';
import Settings from './pages/Settings';
import MainLayout from './layouts/MainLayout';

// Protected: Only show content if logged in, otherwise Redirect to /
const ProtectedRoute = ({ children }) => {
  const { shop } = useAuth();
  if (!shop) return <Navigate to="/" replace />;
  return <MainLayout>{children}</MainLayout>;
};

// Public: Only show Login/Register if NOT logged in, otherwise skip to Dashboard
const PublicRoute = ({ children }) => {
  const { shop } = useAuth();
  if (shop) return <Navigate to="/dashboard" replace />;
  return children;
};

function App() {
  return (
    <Router>
      <AuthProvider>
        <Routes>
          {/* Default Path (ROOT) is LOGIN UI */}
          <Route path="/" element={<PublicRoute><Login /></PublicRoute>} />
          
          {/* Register & Recovery Paths */}
          <Route path="/register" element={<PublicRoute><Register /></PublicRoute>} />
          <Route path="/forgot-password" element={<PublicRoute><ForgotPassword /></PublicRoute>} />
          
          {/* Internal Dashboard Pages */}
          <Route path="/dashboard" element={<ProtectedRoute><Dashboard /></ProtectedRoute>} />
          <Route path="/products" element={<ProtectedRoute><Products /></ProtectedRoute>} />
          <Route path="/customers" element={<ProtectedRoute><Customers /></ProtectedRoute>} />
          <Route path="/sales" element={<ProtectedRoute><Sales /></ProtectedRoute>} />
          <Route path="/bill-history" element={<ProtectedRoute><BillHistory /></ProtectedRoute>} />
          <Route path="/analytics" element={<ProtectedRoute><Analytics /></ProtectedRoute>} />
          <Route path="/settings" element={<ProtectedRoute><Settings /></ProtectedRoute>} />
          
          {/* Default Fallback for anything else */}
          <Route path="*" element={<Navigate to="/" replace />} />
        </Routes>
      </AuthProvider>
    </Router>
  );
}

export default App;
