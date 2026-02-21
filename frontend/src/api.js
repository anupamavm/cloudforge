import axios from 'axios';

const BASE_URL = import.meta.env.VITE_API_URL || 'http://localhost:5000';

const api = axios.create({ baseURL: BASE_URL });

api.interceptors.request.use((config) => {
  const token = localStorage.getItem('token');
  if (token) {
    config.headers.Authorization = `Bearer ${token}`;
  }
  return config;
});

export const getTenants = () => api.get('/api/tenants');
export const createTenant = (data) => api.post('/api/tenants', data);
export const register = (tenantSlug, data) => api.post(`/api/tenants/${tenantSlug}/register`, data);
export const login = (tenantSlug, data) => api.post(`/api/tenants/${tenantSlug}/login`, data);
export const getTodos = (tenantSlug) => api.get(`/api/tenants/${tenantSlug}/todos`);
export const createTodo = (tenantSlug, data) => api.post(`/api/tenants/${tenantSlug}/todos`, data);
export const toggleTodo = (tenantSlug, todoId) => api.patch(`/api/tenants/${tenantSlug}/todos/${todoId}`);
export const deleteTodo = (tenantSlug, todoId) => api.delete(`/api/tenants/${tenantSlug}/todos/${todoId}`);
