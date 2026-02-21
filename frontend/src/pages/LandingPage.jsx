import { useState, useEffect } from 'react';
import { useNavigate } from 'react-router-dom';
import { getTenants, createTenant } from '../api';

export default function LandingPage() {
  const navigate = useNavigate();
  const [tenants, setTenants] = useState([]);
  const [newName, setNewName] = useState('');
  const [newSlug, setNewSlug] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(true);
  const [creating, setCreating] = useState(false);

  useEffect(() => {
    getTenants()
      .then((res) => setTenants(res.data))
      .catch(() => setError('Failed to load tenants'))
      .finally(() => setLoading(false));
  }, []);

  const handleCreate = async (e) => {
    e.preventDefault();
    setError('');
    setCreating(true);
    try {
      const res = await createTenant({ name: newName, slug: newSlug });
      setTenants((prev) => [...prev, res.data]);
      setNewName('');
      setNewSlug('');
    } catch (err) {
      setError(err.response?.data?.message || 'Failed to create tenant');
    } finally {
      setCreating(false);
    }
  };

  return (
    <div className="page landing">
      <h1>CloudForge</h1>
      <p className="subtitle">Multi-Tenant Todo SaaS</p>

      <div className="card">
        <h2>Select Your Workspace</h2>
        {loading ? (
          <p>Loading workspaces…</p>
        ) : tenants.length === 0 ? (
          <p>No workspaces yet. Create one below.</p>
        ) : (
          <ul className="tenant-list">
            {tenants.map((t) => (
              <li key={t.id}>
                <button className="tenant-btn" onClick={() => navigate(`/${t.slug}/login`)}>
                  {t.name}
                  <span className="slug">/{t.slug}</span>
                </button>
              </li>
            ))}
          </ul>
        )}
      </div>

      <div className="card">
        <h2>Create New Workspace</h2>
        {error && <p className="error">{error}</p>}
        <form onSubmit={handleCreate}>
          <input
            placeholder="Workspace name"
            value={newName}
            onChange={(e) => {
              setNewName(e.target.value);
              setNewSlug(e.target.value.toLowerCase().replace(/[^a-z0-9]+/g, '-').replace(/^-|-$/g, ''));
            }}
            required
          />
          <input
            placeholder="slug (auto-generated)"
            value={newSlug}
            onChange={(e) => setNewSlug(e.target.value.toLowerCase().replace(/[^a-z0-9-]/g, ''))}
            pattern="[a-z0-9-]+"
            title="Lowercase letters, numbers, hyphens only"
            required
          />
          <button type="submit" disabled={creating}>
            {creating ? 'Creating…' : 'Create Workspace'}
          </button>
        </form>
      </div>
    </div>
  );
}
