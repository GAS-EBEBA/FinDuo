import 'dotenv/config';
import path from 'node:path';
import { z } from 'zod';

const envSchema = z.object({
  NODE_ENV: z.enum(['development', 'test', 'production']).default('development'),
  API_HOST: z.string().default('0.0.0.0'),
  API_PORT: z.coerce.number().int().min(1).max(65535).default(3000),
  CORS_ORIGINS: z.string().default('http://localhost:5173,http://127.0.0.1:5173'),
  MYSQL_HOST: z.string().default('127.0.0.1'),
  MYSQL_PORT: z.coerce.number().int().min(1).max(65535).default(3306),
  MYSQL_DATABASE: z.string().default('finduo'),
  MYSQL_USER: z.string().default('finduo_app'),
  MYSQL_PASSWORD: z.string().min(1, 'MYSQL_PASSWORD doit être défini dans backend/.env'),
  MYSQL_CONNECTION_LIMIT: z.coerce.number().int().min(1).max(100).default(10),
  UPLOAD_DIR: z.string().default('./storage/uploads'),
  MAX_VIDEO_SIZE_MB: z.coerce.number().int().min(1).max(2048).default(250),
});

const parsed = envSchema.safeParse(process.env);
if (!parsed.success) {
  const details = parsed.error.issues
    .map((issue) => `${issue.path.join('.')}: ${issue.message}`)
    .join('\n');
  throw new Error(`Configuration invalide. Vérifiez backend/.env :\n${details}`);
}

const values = parsed.data;

export const config = {
  ...values,
  corsOrigins: values.CORS_ORIGINS.split(',').map((origin) => origin.trim()).filter(Boolean),
  uploadDirectory: path.resolve(process.cwd(), values.UPLOAD_DIR),
  maxVideoSizeBytes: values.MAX_VIDEO_SIZE_MB * 1024 * 1024,
};
