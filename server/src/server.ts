import { connectDB } from './config/db';
import app from './app';
import { config } from './config/env';
import { logger, logStartupBanner } from './utils/logger';

async function main() {
  logger.info('Starting FocusTrail Server...', { module: 'Bootstrap' });
  logger.info(`Environment: ${process.env.NODE_ENV || 'development'}`, { module: 'Bootstrap' });
  logger.info(`Port: ${config.port}`, { module: 'Bootstrap' });
  logger.info(`CORS Origins: ${config.corsOrigins.join(', ')}`, { module: 'Bootstrap' });
  
  await connectDB();
  
  app.listen(config.port, () => {
    logStartupBanner(config.port);
    logger.success('Server is ready to accept connections! 🎉', { module: 'Bootstrap' });
  });
}

main().catch((err) => {
  logger.error('Fatal error during server startup', { module: 'Bootstrap', error: err });
  process.exit(1);
});
