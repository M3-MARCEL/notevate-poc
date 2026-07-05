const BASE = process.env.REACT_APP_API_URL || "http://localhost:8000";

const headers = (token) => ({
  "Content-Type": "application/json",
  ...(token && { Authorization: `Bearer ${token}` }),
});

export const api = {
  register: (data) =>
    fetch(`${BASE}/api/users/register`, { method: "POST", headers: headers(), body: JSON.stringify(data) }).then(r => r.json()),

  login: (data) =>
    fetch(`${BASE}/api/users/login`, { method: "POST", headers: headers(), body: JSON.stringify(data) }).then(r => r.json()),

  getEntries: (token, params = "") =>
    fetch(`${BASE}/api/entries/${params}`, { headers: headers(token) }).then(r => r.json()),

  createEntry: (token, data) =>
    fetch(`${BASE}/api/entries/`, { method: "POST", headers: headers(token), body: JSON.stringify(data) }).then(r => r.json()),

  updateEntry: (token, id, data) =>
    fetch(`${BASE}/api/entries/${id}`, { method: "PUT", headers: headers(token), body: JSON.stringify(data) }).then(r => r.json()),

  getOverdue: (token) =>
    fetch(`${BASE}/api/entries/overdue`, { headers: headers(token) }).then(r => r.json()),

  applyDecision: (token, id, data) =>
    fetch(`${BASE}/api/entries/${id}/decision`, { method: "POST", headers: headers(token), body: JSON.stringify(data) }).then(r => r.json()),
};
