import { User } from '../../models/User';
import { hashPassword, comparePassword } from '../../utils/password';
import { signToken } from '../../utils/jwt';
import { ApiError } from '../../utils/ApiError';
import { logger } from '../../utils/logger';
import type { RegisterDto, LoginDto } from './auth.schemas';

export async function registerUser(dto: RegisterDto) {
  logger.db('CHECK', 'users', { data: { email: dto.email } });
  const existing = await User.findOne({ email: dto.email });
  if (existing) {
    logger.warn(`Registration blocked: Email already exists - ${dto.email}`, { module: 'AuthService' });
    throw ApiError.conflict('Email already in use');
  }

  logger.debug('Hashing password', { module: 'AuthService' });
  const hashed = await hashPassword(dto.password);
  
  logger.db('CREATE', 'users', { data: { email: dto.email, name: dto.name } });
  const user = await User.create({ email: dto.email, password: hashed, name: dto.name });
  logger.success(`User created: ${user.id}`, { module: 'AuthService' });

  logger.debug('Generating JWT token', { module: 'AuthService' });
  const accessToken = signToken({ userId: user.id as string });
  
  return { accessToken, user };
}

export async function loginUser(dto: LoginDto) {
  logger.db('FIND', 'users', { data: { email: dto.email } });
  const user = await User.findOne({ email: dto.email });
  if (!user) {
    logger.warn(`Login failed: User not found - ${dto.email}`, { module: 'AuthService' });
    throw ApiError.unauthorized('Invalid credentials');
  }

  logger.debug('Verifying password', { module: 'AuthService' });
  const valid = await comparePassword(dto.password, user.password);
  if (!valid) {
    logger.warn(`Login failed: Invalid password - ${dto.email}`, { module: 'AuthService' });
    throw ApiError.unauthorized('Invalid credentials');
  }

  logger.debug('Generating JWT token', { module: 'AuthService' });
  const accessToken = signToken({ userId: user.id as string });
  logger.success(`Login successful: ${user.id}`, { module: 'AuthService' });
  
  return { accessToken, user };
}

export async function getMe(userId: string) {
  logger.db('FIND_BY_ID', 'users', { data: { userId } });
  const user = await User.findById(userId).select('-password');
  if (!user) {
    logger.warn(`User not found: ${userId}`, { module: 'AuthService' });
    throw ApiError.notFound('User not found');
  }
  logger.success(`User profile retrieved: ${userId}`, { module: 'AuthService' });
  return user;
}
