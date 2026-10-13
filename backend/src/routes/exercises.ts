import { Router } from 'express';
import { createReadStream } from 'node:fs';
import { stat } from 'node:fs/promises';
import path from 'node:path';
import type { RowDataPacket } from 'mysql2';
import { z } from 'zod';
import { config } from '../config.js';
import { database } from '../database.js';

export const exercisesRouter = Router();

const listQuerySchema = z.object({
  category: z.string().trim().min(1).max(80).optional(),
  difficulty: z.enum(['beginner', 'intermediate', 'advanced']).optional(),
});

type ExerciseRow = RowDataPacket & {
  id: string;
  title: string;
  description: string | null;
  category: string;
  difficulty: 'beginner' | 'intermediate' | 'advanced';
  duration_seconds: number | null;
  repetitions: number | null;
  video_path: string;
  video_mime_type: string;
  cover_image_path: string | null;
};

function toPublicExercise(row: ExerciseRow) {
  return {
    id: row.id,
    title: row.title,
    description: row.description,
    category: row.category,
    difficulty: row.difficulty,
    durationSeconds: row.duration_seconds,
    repetitions: row.repetitions,
    videoUrl: `/api/v1/exercises/${row.id}/video`,
    coverImageUrl: row.cover_image_path,
  };
}

exercisesRouter.get('/', async (request, response, next) => {
  try {
    const filters = listQuerySchema.parse(request.query);
    const conditions = ["status = 'published'"];
    const values: string[] = [];

    if (filters.category !== undefined) {
      conditions.push('category = ?');
      values.push(filters.category);
    }
    if (filters.difficulty !== undefined) {
      conditions.push('difficulty = ?');
      values.push(filters.difficulty);
    }

    const [rows] = await database.execute<ExerciseRow[]>(
      `SELECT id, title, description, category, difficulty, duration_seconds, repetitions, video_path, video_mime_type, cover_image_path
       FROM exercises WHERE ${conditions.join(' AND ')} ORDER BY sort_order ASC, published_at DESC`,
      values,
    );

    response.json({ data: rows.map(toPublicExercise) });
  } catch (error) {
    next(error);
  }
});

exercisesRouter.get('/:id/video', async (request, response, next) => {
  try {
    const id = z.string().uuid().parse(request.params.id);
    const [rows] = await database.execute<ExerciseRow[]>(
      `SELECT id, title, description, category, difficulty, duration_seconds, repetitions, video_path, video_mime_type, cover_image_path
       FROM exercises WHERE id = ? AND status = 'published' LIMIT 1`,
      [id],
    );
    const exercise = rows[0];
    if (exercise === undefined) {
      response.status(404).json({ error: { code: 'VIDEO_NOT_FOUND', message: 'Vidéo introuvable.' } });
      return;
    }

    const filename = path.basename(exercise.video_path);
    if (filename !== exercise.video_path) {
      response.status(404).json({ error: { code: 'VIDEO_NOT_FOUND', message: 'Vidéo introuvable.' } });
      return;
    }

    const filePath = path.join(config.uploadDirectory, filename);
    const file = await stat(filePath);
    const rangeHeader = request.header('range');
    response.setHeader('Content-Type', exercise.video_mime_type);
    response.setHeader('Accept-Ranges', 'bytes');
    response.setHeader('Cache-Control', 'public, max-age=300');

    if (rangeHeader === undefined) {
      response.setHeader('Content-Length', file.size);
      createReadStream(filePath).pipe(response);
      return;
    }

    const rangeMatch = /^bytes=(\d*)-(\d*)$/.exec(rangeHeader);
    if (rangeMatch === null || file.size === 0) {
      response.setHeader('Content-Range', `bytes */${file.size}`);
      response.sendStatus(416);
      return;
    }

    const start = rangeMatch[1] === ''
      ? Math.max(0, file.size - Number(rangeMatch[2]))
      : Number(rangeMatch[1]);
    const end = rangeMatch[1] === '' || rangeMatch[2] === ''
      ? file.size - 1
      : Math.min(Number(rangeMatch[2]), file.size - 1);
    if (!Number.isSafeInteger(start) || !Number.isSafeInteger(end) || start > end || start >= file.size) {
      response.setHeader('Content-Range', `bytes */${file.size}`);
      response.sendStatus(416);
      return;
    }

    response.status(206);
    response.setHeader('Content-Range', `bytes ${start}-${end}/${file.size}`);
    response.setHeader('Content-Length', end - start + 1);
    createReadStream(filePath, { start, end }).pipe(response);
  } catch (error) {
    if (error instanceof Error && 'code' in error && error.code === 'ENOENT') {
      response.status(404).json({ error: { code: 'VIDEO_NOT_FOUND', message: 'Vidéo introuvable.' } });
      return;
    }
    next(error);
  }
});
