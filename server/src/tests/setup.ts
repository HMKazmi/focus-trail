/// <reference types="vitest/globals" />
// Set required env vars BEFORE any module imports
process.env['MONGODB_URI'] = 'mongodb://localhost:27017/test-placeholder';
process.env['JWT_SECRET'] = 'test-secret-for-vitest-at-least-32-chars!!';
process.env['JWT_EXPIRES_IN'] = '1h';

import mongoose from 'mongoose';
import { MongoMemoryServer } from 'mongodb-memory-server';

let mongod: MongoMemoryServer;

beforeAll(async () => {
  mongod = await MongoMemoryServer.create();
  await mongoose.connect(mongod.getUri());
});

afterAll(async () => {
  await mongoose.disconnect();
  await mongod.stop();
});

afterEach(async () => {
  const collections = mongoose.connection.collections;
  for (const key in collections) {
    await collections[key]?.deleteMany({});
  }
});
