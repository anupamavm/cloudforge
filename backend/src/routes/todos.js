const router = require('express').Router({ mergeParams: true });
const pool = require('../config/db');
const auth = require('../middleware/auth');

// All todo routes require authentication
router.use(auth);

// Middleware: verify the token's tenantId matches the route's tenantSlug
const tenantGuard = async (req, res, next) => {
  const { tenantSlug } = req.params;
  try {
    const result = await pool.query(
      'SELECT id FROM tenants WHERE slug = $1',
      [tenantSlug]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Tenant not found' });
    }
    const tenantId = result.rows[0].id;
    if (req.user.tenantId !== tenantId) {
      return res.status(403).json({ message: 'Access denied: wrong tenant' });
    }
    req.tenantId = tenantId;
    next();
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
};

router.use(tenantGuard);

// GET /api/tenants/:tenantSlug/todos
router.get('/', async (req, res) => {
  try {
    const result = await pool.query(
      `SELECT t.id, t.title, t.completed, t.created_at, u.email AS created_by
       FROM todos t
       JOIN users u ON t.user_id = u.id AND u.tenant_id = $1
       WHERE t.tenant_id = $1
       ORDER BY t.created_at DESC`,
      [req.tenantId]
    );
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

// POST /api/tenants/:tenantSlug/todos
router.post('/', async (req, res) => {
  const { title } = req.body;
  if (!title || !title.trim()) {
    return res.status(400).json({ message: 'Title is required' });
  }
  try {
    const result = await pool.query(
      'INSERT INTO todos (tenant_id, user_id, title) VALUES ($1, $2, $3) RETURNING *',
      [req.tenantId, req.user.userId, title.trim()]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

// PATCH /api/tenants/:tenantSlug/todos/:todoId  - toggle completed
router.patch('/:todoId', async (req, res) => {
  const { todoId } = req.params;
  try {
    const result = await pool.query(
      `UPDATE todos SET completed = NOT completed
       WHERE id = $1 AND tenant_id = $2
       RETURNING *`,
      [todoId, req.tenantId]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Todo not found' });
    }
    res.json(result.rows[0]);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

// DELETE /api/tenants/:tenantSlug/todos/:todoId
router.delete('/:todoId', async (req, res) => {
  const { todoId } = req.params;
  try {
    const result = await pool.query(
      'DELETE FROM todos WHERE id = $1 AND tenant_id = $2 RETURNING id',
      [todoId, req.tenantId]
    );
    if (result.rows.length === 0) {
      return res.status(404).json({ message: 'Todo not found' });
    }
    res.json({ message: 'Todo deleted' });
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
