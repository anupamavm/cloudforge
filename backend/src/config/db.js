const { Pool } = require("pg");
require("dotenv").config();

// Support both DATABASE_URL (local) and individual env vars (AWS ECS)
const pool = new Pool({
	connectionString:
		process.env.DATABASE_URL ||
		`postgresql://${process.env.DB_USER}:${process.env.DB_PASSWORD}@${process.env.DB_HOST}:${process.env.DB_PORT}/${process.env.DB_NAME}`,
});

module.exports = pool;
