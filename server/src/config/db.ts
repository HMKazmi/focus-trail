import mongoose from 'mongoose';
import { config } from './env';
import { logger } from '../utils/logger';

export async function connectDB(): Promise<void> {
  try {
    logger.info('Attempting to connect to MongoDB...', { module: 'Database' });
    logger.debug(`MongoDB URI: ${config.mongoUri.replace(/:[^:@]+@/, ':****@')}`, { module: 'Database' });
    
    await mongoose.connect(config.mongoUri);
    
    logger.success('Successfully connected to MongoDB! ✓', { module: 'Database' });
    logger.info(`Database: ${mongoose.connection.db?.databaseName}`, { module: 'Database' });
    logger.info(`Host: ${mongoose.connection.host}`, { module: 'Database' });
  } catch (err) {
    logger.error('Failed to connect to MongoDB', { module: 'Database', error: err });
    logger.error('Please check your MONGODB_URI in .env file', { module: 'Database' });
    process.exit(1);
  }
  
  // Log MongoDB events
  mongoose.connection.on('disconnected', () => {
    logger.warn('MongoDB disconnected', { module: 'Database' });
  });
  
  mongoose.connection.on('reconnected', () => {
    logger.success('MongoDB reconnected', { module: 'Database' });
  });
  
  mongoose.connection.on('error', (err) => {
    logger.error('MongoDB connection error', { module: 'Database', error: err });
  });
}
