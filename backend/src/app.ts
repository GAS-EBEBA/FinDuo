import cors from 'cors';
import express, { type ErrorRequestHandler } from 'express';
import helmet from 'helmet';
import { rateLimit } from 'express-rate-limit';
import { ZodError } from 'zod';
import { config } from './config.js';
import { database } from './database.js';
import { exercisesRouter } from './routes/exercises.js';

export const app = express();

app.disable('x-powered-by');
app.use(helmet());
app.use(cors({
  origin(origin, callback) {
    // Native Flutter clients do not send an Origin header.
    if (origin === undefined || config.corsOrigins.includes(origin)) {
      callback(null, true);
      return;
    }
    callback(new Error('Origine non autorisée.'));
  },
}));
app.use(express.json({ limit: '256kb' }));
app.use(rateLimit({ windowMs: 60_000, limit: 120, standardHeaders: 'draft-7', legacyHeaders: false }));

app.get('/health', (_request, response) => {
  response.json({ status: 'ok', service: 'finduo-api' });
});

app.get('/ready', async (_request, response) => {
  try {
    await database.query('SELECT 1');
    response.json({ status: 'ready', database: 'connected' });
  } catch {
    response.status(503).json({ status: 'not_ready', database: 'unavailable' });
  }
});

app.use('/api/v1/exercises', exercisesRouter);

app.use((_request, response) => {
  response.status(404).json({ error: { code: 'NOT_FOUND', message: 'Ressource introuvable.' } });
});

const errorHandler: ErrorRequestHandler = (error: unknown, _request, response, _next) => {
  if (error instanceof ZodError) {
    response.status(400).json({
      error: {
        code: 'VALIDATION_ERROR',
        message: 'Les données envoyées sont invalides.',
        details: error.issues.map(({ path, message }) => ({ path: path.join('.'), message })),
      },
    });
    return;
  }

  if (error instanceof Error && error.message === 'Origine non autorisée.') {
    response.status(403).json({ error: { code: 'ORIGIN_FORBIDDEN', message: error.message } });
    return;
  }

  console.error('Erreur API non gérée:', error);
  response.status(500).json({ error: { code: 'INTERNAL_ERROR', message: 'Une erreur interne est survenue.' } });
};

app.use(errorHandler);
