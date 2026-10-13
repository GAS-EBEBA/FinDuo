import mysql from 'mysql2/promise';
import { config } from './config.js';

export const database = mysql.createPool({
  host: config.MYSQL_HOST,
  port: config.MYSQL_PORT,
  database: config.MYSQL_DATABASE,
  user: config.MYSQL_USER,
  password: config.MYSQL_PASSWORD,
  connectionLimit: config.MYSQL_CONNECTION_LIMIT,
  charset: 'utf8mb4',
  decimalNumbers: true,
  enableKeepAlive: true,
});

export async function closeDatabase(): Promise<void> {
  await database.end();
}
