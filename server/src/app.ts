import express from 'express';
import cors from 'cors';
import morgan from 'morgan';
import swaggerUi from 'swagger-ui-express';

import { config } from './config/env';
import { errorHandler } from './middlewares/error';
import { requestLogger } from './utils/logger';
import authRoutes from './modules/auth/auth.routes';
import tasksRoutes from './modules/tasks/tasks.routes';
import { openApiSpec } from './docs/openapi';

const app = express();

// ── CORS ────────────────────────────────────────────────────────────────────
app.use(
  cors({
    origin: true, // Allow all origins for development
    credentials: true,
  }),
);

// ── Core middleware ──────────────────────────────────────────────────────────
app.use(express.json());
app.use(morgan('dev'));
app.use(requestLogger); // Custom detailed logging

// ── Swagger UI ───────────────────────────────────────────────────────────────
app.use('/docs', swaggerUi.serve, swaggerUi.setup(openApiSpec));

// ── Health check ─────────────────────────────────────────────────────────────
app.get('/health', (_req, res) => {
  res.json({ success: true, status: 'ok', timestamp: new Date().toISOString() });
});

// ── API routes ────────────────────────────────────────────────────────────────
app.use('/api/auth', authRoutes);
app.use('/api/tasks', tasksRoutes);

// ── 404 handler ───────────────────────────────────────────────────────────────
app.use((_req, res) => {
  res.status(404).json({ success: false, error: { message: 'Route not found', statusCode: 404 } });
});

// ── Global error handler ──────────────────────────────────────────────────────
app.use(errorHandler);

export default app;
