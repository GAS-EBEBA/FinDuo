import { app } from './app.js';
import { closeDatabase, database } from './database.js';
import { config } from './config.js';

const server = app.listen(config.API_PORT, config.API_HOST, () => {
  console.log(`FinDuo API à l'écoute sur http://localhost:${config.API_PORT}`);
  void database.query('SELECT 1')
    .then(() => console.log('MySQL : connexion vérifiée.'))
    .catch(() => console.warn('MySQL : indisponible. Démarrez le serveur et vérifiez backend/.env.'));
});

async function shutdown(signal: string): Promise<void> {
  console.log(`${signal} reçu : arrêt de l'API...`);
  server.close(async () => {
    await closeDatabase();
    process.exit(0);
  });
}

process.on('SIGINT', () => void shutdown('SIGINT'));
process.on('SIGTERM', () => void shutdown('SIGTERM'));
