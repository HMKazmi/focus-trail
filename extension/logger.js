/* ═══════════════════════════════════════════════════════════════
   FocusTrail Extension – Logger
   Simple, colored console logging for the Chrome extension
   ═══════════════════════════════════════════════════════════════ */
'use strict';

const Logger = {
  // ANSI color codes for console (works in Chrome DevTools)
  _colors: {
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
    bgRed: '\x1b[41m',
    bgGreen: '\x1b[42m',
    bgYellow: '\x1b[43m',
    bgBlue: '\x1b[44m',
  },

  _enabled: true,
  _level: 'info', // 'debug' | 'info' | 'warn' | 'error' - default to 'info' to hide debug logs

  /**
   * Configure logger
   * @param {Object} config - { enabled: boolean, level: string }
   */
  config(config) {
    if (config.enabled !== undefined) this._enabled = config.enabled;
    if (config.level) this._level = config.level;
  },

  _shouldLog(level) {
    if (!this._enabled) return false;
    const levels = { debug: 0, info: 1, warn: 2, error: 3 };
    return levels[level] >= levels[this._level];
  },

  _timestamp() {
    return new Date().toISOString();
  },

  _format(level, module, message, data) {
    const timestamp = this._timestamp();
    const { bright, dim, reset } = this._colors;
    let color = '';
    let icon = '';

    switch (level) {
      case 'debug':
        color = this._colors.cyan;
        icon = '🔍';
        break;
      case 'info':
        color = this._colors.blue;
        icon = 'ℹ️';
        break;
      case 'success':
        color = this._colors.green;
        icon = '✅';
        break;
      case 'warn':
        color = this._colors.yellow;
        icon = '⚠️';
        break;
      case 'error':
        color = this._colors.red;
        icon = '❌';
        break;
      case 'api':
        color = this._colors.magenta;
        icon = '🌐';
        break;
    }

    const moduleStr = module ? `[${module}]` : '';
    return `${dim}${timestamp}${reset} ${icon} ${color}${bright}${level.toUpperCase()}${reset} ${color}${moduleStr}${reset} ${message}`;
  },

  /**
   * Debug log - detailed information for development
   * @param {string} message 
   * @param {string} module 
   * @param {*} data 
   */
  debug(message, module = '', data = null) {
    if (!this._shouldLog('debug')) return;
    console.log(this._format('debug', module, message));
    if (data) console.log('  ↳ Data:', data);
  },

  /**
   * Info log - general information
   * @param {string} message 
   * @param {string} module 
   * @param {*} data 
   */
  info(message, module = '', data = null) {
    if (!this._shouldLog('info')) return;
    console.log(this._format('info', module, message));
    if (data) console.log('  ↳ Data:', data);
  },

  /**
   * Success log - successful operations
   * @param {string} message 
   * @param {string} module 
   * @param {*} data 
   */
  success(message, module = '', data = null) {
    if (!this._shouldLog('info')) return;
    console.log(this._format('success', module, message));
    if (data) console.log('  ↳ Data:', data);
  },

  /**
   * Warn log - warnings
   * @param {string} message 
   * @param {string} module 
   * @param {*} data 
   */
  warn(message, module = '', data = null) {
    if (!this._shouldLog('warn')) return;
    console.warn(this._format('warn', module, message));
    if (data) console.log('  ↳ Data:', data);
  },

  /**
   * Error log - errors
   * @param {string} message 
   * @param {string} module 
   * @param {Error|*} error 
   */
  error(message, module = '', error = null) {
    if (!this._shouldLog('error')) return;
    console.error(this._format('error', module, message));
    if (error) {
      if (error instanceof Error) {
        console.error('  ↳ Error:', error.message);
        if (error.stack) console.error('  ↳ Stack:', error.stack);
      } else {
        console.error('  ↳ Error:', error);
      }
    }
  },

  /**
   * API log - API calls (request/response)
   * @param {string} method 
   * @param {string} path 
   * @param {number} status 
   * @param {*} data 
   */
  api(method, path, status, data = null) {
    if (!this._shouldLog('debug')) return;
    const statusColor = status >= 200 && status < 300 
      ? this._colors.green 
      : status >= 400 && status < 500
      ? this._colors.yellow
      : this._colors.red;
    
    console.log(
      `${this._colors.dim}${this._timestamp()}${this._colors.reset} ` +
      `🌐 ${this._colors.magenta}${this._colors.bright}API${this._colors.reset} ` +
      `${this._colors.cyan}${method}${this._colors.reset} ${path} ` +
      `${statusColor}${status}${this._colors.reset}`
    );
    if (data) console.log('  ↳ Response:', data);
  },

  /**
   * Group logs together
   * @param {string} label 
   */
  group(label) {
    console.group(`📦 ${label}`);
  },

  groupEnd() {
    console.groupEnd();
  },

  /**
   * Print extension banner
   */
  banner() {
    const { bright, green, cyan, dim, reset } = this._colors;
    console.log('\n');
    console.log(`${bright}${green}   ___                 _____           _ _ ${reset}`);
    console.log(`${bright}${green}  / __\\__   ___ _   _/__   \\___ _ __ (_) |${reset}`);
    console.log(`${bright}${green} / _\\/ _ \\ / __| | | | / /\\/ _  |  _|| | |${reset}`);
    console.log(`${bright}${green}/ / | (_) | (__| |_| |/ / | |_| | |  | | |${reset}`);
    console.log(`${bright}${green}\\/   \\___/ \\___|\\__,_|\\/   \\__,_|_|  |_|_|${reset}`);
    console.log('');
    console.log(`${bright}${cyan}🎯 FocusTrail Chrome Extension${reset}`);
    console.log(`${dim}   Offline-First Productivity Tracker${reset}`);
    console.log(`${dim}   Version: 1.0.0${reset}\n`);
  }
};

// Auto-print banner when extension loads
Logger.banner();

// Export for use in popup.js
if (typeof window !== 'undefined') {
  window.Logger = Logger;
}

