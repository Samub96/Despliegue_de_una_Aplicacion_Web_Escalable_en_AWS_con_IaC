// Configuración básica del frontend para comunicar con backend
const API_BASE = 'http://localhost:8080/api';

function getToken() {
  return localStorage.getItem('token');
}
function setToken(token) {
  localStorage.setItem('token', token);
}
function clearToken() {
  localStorage.removeItem('token');
}

function authHeaders() {
  const t = getToken();
  return t ? { 'Authorization': 'Bearer ' + t } : {};
}

async function apiFetch(path, opts = {}) {
  const url = API_BASE + path;
  const options = {
    headers: { 'Content-Type': 'application/json', ...(opts.headers || {}) },
    ...opts
  };
  if (options.body && typeof options.body !== 'string') {
    options.body = JSON.stringify(options.body);
  }
  const res = await fetch(url, options);
  const contentType = res.headers.get('content-type') || '';
  const data = contentType.includes('application/json') ? await res.json() : await res.text();
  if (!res.ok) throw data;
  return data;
}