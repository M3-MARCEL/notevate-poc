import React, { useState, useEffect } from "react";
import { api } from "../api";

const S = {
  page:    { minHeight:"100vh", background:"#EFF3F7", fontFamily:"Arial,sans-serif" },
  header:  { background:"#1F4E79", color:"#fff", padding:"14px 28px",
             display:"flex", justifyContent:"space-between", alignItems:"center" },
  logo:    { fontSize:22, fontWeight:"bold" },
  logoutB: { background:"transparent", border:"1px solid #fff", color:"#fff",
             padding:"6px 16px", borderRadius:6, cursor:"pointer", fontSize:13 },
  main:    { maxWidth:900, margin:"28px auto", padding:"0 16px" },
  grid:    { display:"grid", gridTemplateColumns:"1fr 1fr", gap:16, marginBottom:24 },
  card:    { background:"#fff", borderRadius:10, padding:20,
             boxShadow:"0 2px 8px rgba(0,0,0,0.08)" },
  ctitle:  { color:"#1F4E79", fontWeight:"bold", fontSize:16, marginBottom:12 },
  form:    { display:"flex", flexDirection:"column", gap:8 },
  input:   { padding:"9px 12px", border:"1px solid #BFBFBF", borderRadius:7, fontSize:14 },
  select:  { padding:"9px 12px", border:"1px solid #BFBFBF", borderRadius:7, fontSize:14 },
  addBtn:  { background:"#2E75B6", color:"#fff", border:"none", borderRadius:7,
             padding:"10px", fontWeight:"bold", cursor:"pointer" },
  entry:   { background:"#F8F9FB", borderRadius:8, padding:"12px 14px", marginBottom:8,
             borderLeft:"4px solid #2E75B6", display:"flex", justifyContent:"space-between" },
  overdueE:{ background:"#FFF3F3", borderRadius:8, padding:"12px 14px", marginBottom:8,
             borderLeft:"4px solid #C00000" },
  badge:   { fontSize:11, padding:"2px 8px", borderRadius:10, background:"#DEEAF1",
             color:"#1F4E79", marginLeft:6 },
  doneBtn: { fontSize:12, padding:"4px 10px", background:"#E2EFDA", border:"none",
             borderRadius:6, cursor:"pointer", color:"#375623" },
  decBtn:  { fontSize:12, padding:"4px 10px", background:"#FCE4D6", border:"none",
             borderRadius:6, cursor:"pointer", color:"#833C00", marginRight:4 },
};

export default function Dashboard({ token, onLogout }) {
  const [entries, setEntries]   = useState([]);
  const [overdue, setOverdue]   = useState([]);
  const [newEntry, setNewEntry] = useState({ title:"", type:"task", priority:"normal", due_date:"" });
  const [loading, setLoading]   = useState(true);

  const load = async () => {
    const [all, ov] = await Promise.all([api.getEntries(token), api.getOverdue(token)]);
    setEntries(Array.isArray(all) ? all : []);
    setOverdue(Array.isArray(ov) ? ov : []);
    setLoading(false);
  };

  useEffect(() => { load(); }, []);

  const addEntry = async () => {
    if (!newEntry.title.trim()) return;
    const payload = { ...newEntry };
    if (!payload.due_date) delete payload.due_date;
    await api.createEntry(token, payload);
    setNewEntry({ title:"", type:"task", priority:"normal", due_date:"" });
    load();
  };

  const markDone = async (id) => {
    await api.updateEntry(token, id, { status: "completed" });
    load();
  };

  const applyDecision = async (id, action) => {
    const newDate = action === "reschedule"
      ? prompt("Nueva fecha límite (YYYY-MM-DD):") + "T23:59:00"
      : null;
    const subtasks = action === "split"
      ? prompt("Escribe las subtareas separadas por coma:")?.split(",").map(s=>s.trim()).filter(Boolean)
      : null;
    await api.applyDecision(token, id, { action, new_due_date: newDate, subtasks });
    load();
  };

  const pending = entries.filter(e => e.status === "pending");

  return (
    <div style={S.page}>
      <header style={S.header}>
        <span style={S.logo}>Notevate</span>
        <button style={S.logoutB} onClick={onLogout}>Cerrar sesión</button>
      </header>
      <main style={S.main}>
        {overdue.length > 0 && (
          <div style={{...S.card, marginBottom:16, borderTop:"3px solid #C00000"}}>
            <div style={{...S.ctitle, color:"#C00000"}}>
              ⚠️ Motor de Decisiones — {overdue.length} tarea(s) vencida(s)
            </div>
            {overdue.map(e => (
              <div key={e.id} style={S.overdueE}>
                <div style={{fontWeight:"bold", marginBottom:6}}>{e.title}</div>
                <div>
                  <button style={S.decBtn} onClick={() => applyDecision(e.id,"reschedule")}>Reagendar</button>
                  <button style={S.decBtn} onClick={() => applyDecision(e.id,"split")}>Dividir</button>
                  <button style={S.decBtn} onClick={() => applyDecision(e.id,"discard")}>Descartar</button>
                </div>
              </div>
            ))}
          </div>
        )}
        <div style={S.grid}>
          <div style={S.card}>
            <div style={S.ctitle}>Nueva entrada</div>
            <div style={S.form}>
              <input style={S.input} placeholder="Título..."
                value={newEntry.title} onChange={e => setNewEntry({...newEntry, title:e.target.value})} />
              <select style={S.select} value={newEntry.type}
                onChange={e => setNewEntry({...newEntry, type:e.target.value})}>
                <option value="task">Tarea</option>
                <option value="habit">Hábito</option>
                <option value="project">Proyecto</option>
                <option value="idea">Idea</option>
                <option value="event">Evento</option>
              </select>
              <select style={S.select} value={newEntry.priority}
                onChange={e => setNewEntry({...newEntry, priority:e.target.value})}>
                <option value="low">Prioridad baja</option>
                <option value="normal">Prioridad normal</option>
                <option value="high">Prioridad alta</option>
              </select>
              <input style={S.input} type="datetime-local"
                value={newEntry.due_date} onChange={e => setNewEntry({...newEntry, due_date:e.target.value})} />
              <button style={S.addBtn} onClick={addEntry}>+ Agregar</button>
            </div>
          </div>
          <div style={S.card}>
            <div style={S.ctitle}>Resumen</div>
            <div>Total: <b>{entries.length}</b></div>
            <div>Pendientes: <b>{pending.length}</b></div>
            <div>Vencidas: <b style={{color:"#C00000"}}>{overdue.length}</b></div>
            <div>Completadas: <b>{entries.filter(e=>e.status==="completed").length}</b></div>
          </div>
        </div>
        <div style={S.card}>
          <div style={S.ctitle}>Entradas pendientes</div>
          {loading && <div style={{color:"#595959"}}>Cargando...</div>}
          {!loading && pending.length === 0 && <div style={{color:"#595959"}}>Sin entradas pendientes.</div>}
          {pending.map(e => (
            <div key={e.id} style={S.entry}>
              <div>
                <b>{e.title}</b>
                <span style={S.badge}>{e.type}</span>
                <span style={{...S.badge, background: e.priority==="high"?"#FCE4D6":"#DEEAF1",
                              color: e.priority==="high"?"#833C00":"#1F4E79"}}>{e.priority}</span>
                {e.due_date && <div style={{fontSize:12, color:"#595959", marginTop:4}}>
                  Vence: {new Date(e.due_date).toLocaleDateString("es-CL")}
                </div>}
              </div>
              <button style={S.doneBtn} onClick={() => markDone(e.id)}>✓ Listo</button>
            </div>
          ))}
        </div>
      </main>
    </div>
  );
}
