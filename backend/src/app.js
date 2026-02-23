require("dotenv").config();
const express = require("express");
const cors = require("cors");
const rateLimit = require("express-rate-limit");
const initDb = require("./config/initDb");
const tenantsRouter = require("./routes/tenants");
const authRouter = require("./routes/auth");
const todosRouter = require("./routes/todos");

const app = express();

app.use(cors());
app.use(express.json());

const authLimiter = rateLimit({
	windowMs: 15 * 60 * 1000,
	max: 20,
	standardHeaders: true,
	legacyHeaders: false,
	message: { message: "Too many requests, please try again later" },
});

const tenantsWriteLimiter = rateLimit({
	windowMs: 60 * 60 * 1000,
	max: 10,
	standardHeaders: true,
	legacyHeaders: false,
	message: { message: "Too many requests, please try again later" },
});

const apiLimiter = rateLimit({
	windowMs: 15 * 60 * 1000,
	max: 200,
	standardHeaders: true,
	legacyHeaders: false,
	message: { message: "Too many requests, please try again later" },
});

app.use("/api/tenants", tenantsWriteLimiter, tenantsRouter);
app.use("/api/tenants/:tenantSlug", authLimiter, authRouter);
app.use("/api/tenants/:tenantSlug/todos", apiLimiter, todosRouter);

// Health check endpoints (for ALB and general health monitoring)
app.get("/health", (req, res) => res.json({ status: "ok" }));
app.get("/api/health", (req, res) => res.json({ status: "ok" }));

const PORT = process.env.PORT || 5000;

initDb()
	.then(() => {
		app.listen(PORT, () => console.log(`Backend running on port ${PORT}`));
	})
	.catch((err) => {
		console.error("Failed to initialize database:", err);
		process.exit(1);
	});
