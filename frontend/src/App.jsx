import React, { useState } from "react";
import Login from "./components/Login";
import Dashboard from "./components/Dashboard";

export default function App() {
  const [token, setToken] = useState(localStorage.getItem("nv_token"));

  const handleLogin = (t) => {
    localStorage.setItem("nv_token", t);
    setToken(t);
  };

  const handleLogout = () => {
    localStorage.removeItem("nv_token");
    setToken(null);
  };

  return token
    ? <Dashboard token={token} onLogout={handleLogout} />
    : <Login onLogin={handleLogin} />;
}
