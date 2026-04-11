import React, { createContext, useState, useContext, useEffect } from 'react';

const AuthContext = createContext();

export const AuthProvider = ({ children }) => {
  const [shop, setShop] = useState(null);
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    const storedShop = localStorage.getItem('shop');
    if (storedShop) {
      setShop(JSON.parse(storedShop));
    }
    setLoading(false);
  }, []);

  const loginShop = (data) => {
    localStorage.setItem('token', data.token);
    localStorage.setItem('shop', JSON.stringify(data));
    setShop(data);
  };

  const updateShop = (data) => {
    const updatedData = { ...shop, ...data };
    localStorage.setItem('shop', JSON.stringify(updatedData));
    setShop(updatedData);
  };

  const logoutShop = () => {
    localStorage.removeItem('token');
    localStorage.removeItem('shop');
    setShop(null);
  };

  return (
    <AuthContext.Provider value={{ shop, setShop, updateShop, loading, loginShop, logoutShop }}>
      {!loading && children}
    </AuthContext.Provider>
  );
};

export const useAuth = () => useContext(AuthContext);
