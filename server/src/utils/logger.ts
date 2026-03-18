/**
 * Comprehensive Logging Utility for FocusTrail Server
 * Provides structured, colored console logging for all operations
 */

// ANSI color codes for terminal output
const colors = {
  reset: '\x1b[0m',
  bright: '\x1b[1m',
  dim: '\x1b[2m',
  
  // Foreground colors
  black: '\x1b[30m',
  red: '\x1b[31m',
  green: '\x1b[32m',
  yellow: '\x1b[33m',
  blue: '\x1b[34m',
  magenta: '\x1b[35m',
  cyan: '\x1b[36m',
  white: '\x1b[37m',
  
  // Background colors
  bgBlack: '\x1b[40m',
  bgRed: '\x1b[41m',
  bgGreen: '\x1b[42m',
  bgYellow: '\x1b[43m',
  bgBlue: '\x1b[44m',
  bgMagenta: '\x1b[45m',
  bgCyan: '\x1b[46m',
  bgWhite: '\x1b[47m',
};

type LogLevel = 'INFO' | 'SUCCESS' | 'WARN' | 'ERROR' | 'DEBUG' | 'REQUEST' | 'RESPONSE' | 'DB' | 'AUTH';

interface LogOptions {
  module?: string;
  data?: unknown;
  error?: Error | unknown;
}

function getTimestamp(): string {
  return new Date().toISOString();
}

function formatLevel(level: LogLevel): string {
  const levelColors: Record<LogLevel, string> = {
    INFO: colors.cyan,
    SUCCESS: colors.green,
    WARN: colors.yellow,
    ERROR: colors.red,
    DEBUG: colors.magenta,
    REQUEST: colors.blue,
    RESPONSE: colors.green,
    DB: colors.yellow,
    AUTH: colors.magenta,
  };
  
  return `${levelColors[level]}${colors.bright}[${level}]${colors.reset}`;
}

function log(level: LogLevel, message: string, options: LogOptions = {}): void {
  const timestamp = `${colors.dim}${getTimestamp()}${colors.reset}`;
  const levelStr = formatLevel(level);
  const moduleStr = options.module ? `${colors.cyan}[${options.module}]${colors.reset}` : '';
  
  const logMessage = [timestamp, levelStr, moduleStr, message].filter(Boolean).join(' ');
  console.log(logMessage);
  
  if (options.data) {
    console.log(`${colors.dim}  ↳ Data:${colors.reset}`, JSON.stringify(options.data, null, 2));
  }
  
  if (options.error) {
    console.error(`${colors.red}  ↳ Error:${colors.reset}`, options.error);
  }
}

// Exported logging functions
export const logger = {
  info: (message: string, options?: LogOptions) => log('INFO', message, options),
  success: (message: string, options?: LogOptions) => log('SUCCESS', message, options),
  warn: (message: string, options?: LogOptions) => log('WARN', message, options),
  error: (message: string, options?: LogOptions) => log('ERROR', message, options),
  debug: (message: string, options?: LogOptions) => log('DEBUG', message, options),
  
  // Specialized logging
  request: (method: string, path: string, options?: LogOptions) => {
    log('REQUEST', `${colors.bright}${method}${colors.reset} ${path}`, options);
  },
  
  response: (method: string, path: string, statusCode: number, duration?: number, options?: LogOptions) => {
    const statusColor = statusCode >= 200 && statusCode < 300 ? colors.green : 
                       statusCode >= 400 && statusCode < 500 ? colors.yellow : colors.red;
    const durationStr = duration ? ` ${colors.dim}(${duration}ms)${colors.reset}` : '';
    log('RESPONSE', `${colors.bright}${method}${colors.reset} ${path} ${statusColor}${statusCode}${colors.reset}${durationStr}`, options);
  },
  
  db: (operation: string, collection: string, options?: LogOptions) => {
    log('DB', `${operation} → ${colors.cyan}${collection}${colors.reset}`, options);
  },
  
  auth: (action: string, user?: string, options?: LogOptions) => {
    const userStr = user ? `${colors.cyan}${user}${colors.reset}` : 'unknown';
    log('AUTH', `${action} → ${userStr}`, options);
  },
};

// Request logging middleware
export function requestLogger(req: { method: string; originalUrl: string; body?: unknown; query?: unknown }, _res: unknown, next: () => void): void {
  logger.request(req.method, req.originalUrl, {
    data: {
      body: req.body,
      query: req.query,
    },
  });
  next();
}

// Separator for visual clarity
export function logSeparator(): void {
  console.log(`${colors.dim}${'─'.repeat(80)}${colors.reset}`);
}

// Startup banner
export function logStartupBanner(port: number): void {
  console.log('\n');
  logSeparator();
  console.log(`${colors.bright}${colors.green}   ___                 _____           _ _ ${colors.reset}`);
  console.log(`${colors.bright}${colors.green}  / __\\__   ___ _   _/__   \\___ _ __ (_) |${colors.reset}`);
  console.log(`${colors.bright}${colors.green} / _\\/ _ \\ / __| | | | / /\\/ _  |  _|| | |${colors.reset}`);
  console.log(`${colors.bright}${colors.green}/ / | (_) | (__| |_| |/ / | |_| | |  | | |${colors.reset}`);
  console.log(`${colors.bright}${colors.green}\\/   \\___/ \\___|\\__,_|\\/   \\__,_|_|  |_|_|${colors.reset}`);
  console.log('');
  console.log(`${colors.bright}${colors.cyan}🚀 FocusTrail Server${colors.reset}`);
  console.log(`${colors.dim}   Productivity Tracker REST API${colors.reset}`);
  console.log('');
  console.log(`${colors.green}✓${colors.reset} Server running on ${colors.cyan}http://localhost:${port}${colors.reset}`);
  console.log(`${colors.green}✓${colors.reset} API Documentation at ${colors.cyan}http://localhost:${port}/docs${colors.reset}`);
  console.log(`${colors.green}✓${colors.reset} Health check at ${colors.cyan}http://localhost:${port}/health${colors.reset}`);
  logSeparator();
  console.log('\n');
}
