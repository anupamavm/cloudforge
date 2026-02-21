import { useState, useEffect } from 'react';
import { useParams, useNavigate } from 'react-router-dom';
import { getTodos, createTodo, toggleTodo, deleteTodo } from '../api';
import { useAuth } from '../context/AuthContext';

export default function TodosPage() {
  const { tenantSlug } = useParams();
  const navigate = useNavigate();
  const { user, logout } = useAuth();
  const [todos, setTodos] = useState([]);
  const [newTitle, setNewTitle] = useState('');
  const [error, setError] = useState('');
  const [loading, setLoading] = useState(true);

  useEffect(() => {
    if (!user) {
      navigate(`/${tenantSlug}/login`);
      return;
    }
    if (user.tenantSlug !== tenantSlug) {
      navigate(`/${tenantSlug}/login`);
      return;
    }
    getTodos(tenantSlug)
      .then((res) => setTodos(res.data))
      .catch(() => setError('Failed to load todos'))
      .finally(() => setLoading(false));
  }, [tenantSlug, user, navigate]);

  const handleAdd = async (e) => {
    e.preventDefault();
    if (!newTitle.trim()) return;
    try {
      const res = await createTodo(tenantSlug, { title: newTitle.trim() });
      setTodos((prev) => [res.data, ...prev]);
      setNewTitle('');
    } catch (err) {
      setError(err.response?.data?.message || 'Failed to add todo');
    }
  };

  const handleToggle = async (id) => {
    try {
      const res = await toggleTodo(tenantSlug, id);
      setTodos((prev) => prev.map((t) => (t.id === id ? { ...t, completed: res.data.completed } : t)));
    } catch {
      setError('Failed to update todo');
    }
  };

  const handleDelete = async (id) => {
    try {
      await deleteTodo(tenantSlug, id);
      setTodos((prev) => prev.filter((t) => t.id !== id));
    } catch {
      setError('Failed to delete todo');
    }
  };

  const handleLogout = () => {
    logout();
    navigate('/');
  };

  return (
    <div className="page todos">
      <header className="top-bar">
        <div>
          <h1>CloudForge</h1>
          <span className="tenant-badge">{tenantSlug}</span>
        </div>
        <div className="user-info">
          <span>{user?.email}</span>
          <button className="logout-btn" onClick={handleLogout}>Logout</button>
        </div>
      </header>

      <div className="content">
        <h2>Todo List</h2>

        <form className="add-form" onSubmit={handleAdd}>
          <input
            placeholder="Add a new task…"
            value={newTitle}
            onChange={(e) => setNewTitle(e.target.value)}
          />
          <button type="submit">Add</button>
        </form>

        {error && <p className="error">{error}</p>}

        {loading ? (
          <p>Loading…</p>
        ) : todos.length === 0 ? (
          <p className="empty">No tasks yet. Add one above!</p>
        ) : (
          <ul className="todo-list">
            {todos.map((todo) => (
              <li key={todo.id} className={todo.completed ? 'completed' : ''}>
                <label className="todo-check">
                  <input
                    type="checkbox"
                    checked={todo.completed}
                    onChange={() => handleToggle(todo.id)}
                  />
                  <span className="todo-title">{todo.title}</span>
                </label>
                <div className="todo-meta">
                  <span className="todo-author">{todo.created_by}</span>
                  <button
                    className="delete-btn"
                    onClick={() => handleDelete(todo.id)}
                    aria-label="Delete todo"
                  >
                    ✕
                  </button>
                </div>
              </li>
            ))}
          </ul>
        )}
      </div>
    </div>
  );
}
