const router = require('express').Router();
const pool = require('../config/db');

// POST /api/tenants  - create a new tenant
router.post('/', async (req, res) => {
  const { name, slug } = req.body;
  if (!name || !slug) {
    return res.status(400).json({ message: 'Name and slug are required' });
  }
  const slugPattern = /^[a-z0-9-]+$/;
  if (!slugPattern.test(slug)) {
    return res.status(400).json({ message: 'Slug must be lowercase alphanumeric with hyphens only' });
  }
  try {
    const result = await pool.query(
      'INSERT INTO tenants (name, slug) VALUES ($1, $2) RETURNING id, name, slug',
      [name, slug]
    );
    res.status(201).json(result.rows[0]);
  } catch (err) {
    if (err.code === '23505') {
      return res.status(409).json({ message: 'Tenant name or slug already exists' });
    }
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

// GET /api/tenants - list tenants (for the login page dropdown)
router.get('/', async (req, res) => {
  try {
    const result = await pool.query('SELECT id, name, slug FROM tenants ORDER BY name');
    res.json(result.rows);
  } catch (err) {
    console.error(err);
    res.status(500).json({ message: 'Server error' });
  }
});

module.exports = router;
