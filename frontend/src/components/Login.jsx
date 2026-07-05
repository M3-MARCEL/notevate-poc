import React, { useState } from "react";
import { api } from "../api";

const S = {
  page: { minHeight:"100vh", display:"flex", alignItems:"center", justifyContent:"center",
          background:"#EFF3F7", fontFamily:"Arial,sans-serif" },
  card: { background:"#fff", padding:40, borderRadius:12, width:360,
          boxShadow:"0 4px 20px rgba(0,0,0,0.1)" },
  title: { color:"#1F4E79", fontSize:28, fontWeight:"bold", marginBottom:4, textAlign:"center" },
  sub:   { color:"#595959", fontSize:13, textAlign:"center", marginBottom:28 },
  label: { display:"block", fontSize:13, color:"#595959", marginBottom:4 },
  input: { width:"100%", padding:"10px 12px", border:"1px solid #BFBFBF", borderRadius:8,
           fontSize:14, boxSizing:"border-box", marginBottom:16 },
  btn:   { width:"100%", padding:"12px", background:"#2E75B6", color:"#fff", border:"none",
           borderRadius:8, fontSize:15, cursor:"pointer", fontWeight:"bold" },
  link:  { textAlign:"center", marginTop:16, fontSize:13, color:"#595959" },
  err:   { color:"#C00000", fontSize:13, marginBottom:12 },
};

export default function Login({ onLogin }) {
  const [mode, setMode]       = useState("login");
  const [form, setForm]       = useState({ email:"", password:"", name:"", profile_type:"general" });
  const [error, setError]     = useState("");
  const [loading, setLoading] = useState(false);

  const handle = async () => {
    setLoading(true); setError("");
    const res = mode === "login"
      ? await api.login({ email: form.email, password: form.password })
      : await api.register(form);
    setLoading(false);
    if (res.access_token) onLogin(res.access_token);
    else setError(res.detail || "Error al autenticar");
  };

  return (
    <div style={S.page}>
      <div style={S.card}>
        <div style={S.title}>Notevate</div>
        <div style={S.sub}>{mode === "login" ? "Inicia sesión" : "Crea tu cuenta"}</div>
        {error && <div style={S.err}>{error}</div>}
        {mode === "register" && (
          <>
            <label style={S.label}>Nombre</label>
            <input style={S.input} value={form.name} onChange={e => setForm({...form, name:e.target.value})} />
          </>
        )}
        <label style={S.label}>Email</label>
        <input style={S.input} type="email" value={form.email} onChange={e => setForm({...form, email:e.target.value})} />
        <label style={S.label}>Contraseña</label>
        <input style={S.input} type="password" value={form.password} onChange={e => setForm({...form, password:e.target.value})} />
        <button style={S.btn} onClick={handle} disabled={loading}>
          {loading ? "Cargando..." : mode === "login" ? "Iniciar sesión" : "Registrarse"}
        </button>
        <div style={S.link}>
          {mode === "login" ? <>¿No tienes cuenta? <span style={{color:"#2E75B6",cursor:"pointer"}} onClick={() => setMode("register")}>Regístrate</span></>
                            : <>¿Ya tienes cuenta? <span style={{color:"#2E75B6",cursor:"pointer"}} onClick={() => setMode("login")}>Inicia sesión</span></>}
        </div>
      </div>
    </div>
  );
}
