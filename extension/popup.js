/* ═══════════════════════════════════════════════════════════════
   FocusTrail – popup.js
   ═══════════════════════════════════════════════════════════════ */
'use strict';

/* ── Config (injected by config.js before this script) ─────────── */
const BASE_URL = (typeof CONFIG !== 'undefined' && CONFIG.API_BASE_URL)
  ? CONFIG.API_BASE_URL.replace(/\/$/, '')
  : 'http://localhost:4000';

// Configure logger based on config
if (typeof CONFIG !== 'undefined' && CONFIG.LOG_LEVEL) {
  Logger.config({ level: CONFIG.LOG_LEVEL });
}

Logger.info(`Extension initialized with API base URL: ${BASE_URL}`, 'Init');

/* ══════════════════════════════════════════════════════════════════
   STORAGE HELPERS
   ══════════════════════════════════════════════════════════════════ */
const storage = {
  /** @returns {Promise<{token:string|null, user:object|null, rememberMe:boolean, email:string|null}>} */
  get() {
    return new Promise(resolve =>
      chrome.storage.local.get(['ft_token', 'ft_user', 'ft_remember_me', 'ft_email'], data =>
        resolve({ 
          token: data.ft_token || null, 
          user: data.ft_user || null,
          rememberMe: data.ft_remember_me || false,
          email: data.ft_email || null
        })
      )
    );
  },
  /** @param {string} token @param {object} user */
  set(token, user) {
    return new Promise(resolve =>
      chrome.storage.local.set({ ft_token: token, ft_user: user }, resolve)
    );
  },
  /** @param {boolean} rememberMe @param {string} email */
  setRememberMe(rememberMe, email) {
    return new Promise(resolve =>
      chrome.storage.local.set({ ft_remember_me: rememberMe, ft_email: email }, resolve)
    );
  },
  clear() {
    return new Promise(resolve =>
      chrome.storage.local.remove(['ft_token', 'ft_user'], resolve)
    );
  },
  clearAll() {
    return new Promise(resolve =>
      chrome.storage.local.remove(['ft_token', 'ft_user', 'ft_remember_me', 'ft_email'], resolve)
    );
  },
};

/* ══════════════════════════════════════════════════════════════════
   API CLIENT
   ══════════════════════════════════════════════════════════════════ */
/**
 * Thin fetch wrapper.
 * @param {string} path  – e.g. '/api/tasks'
 * @param {RequestInit} opts
 * @param {string|null} token
 * @returns {Promise<any>} – parsed JSON body (.data property)
 */
async function apiFetch(path, opts = {}, token = null) {
  const url = BASE_URL + path;
  const headers = { 'Content-Type': 'application/json', ...(opts.headers || {}) };
  if (token) headers['Authorization'] = `Bearer ${token}`;

  const method = opts.method || 'GET';
  Logger.debug(`${method} ${path}`, 'API');

  let res;
  try {
    res = await fetch(url, { ...opts, headers });
  } catch (err) {
    // Network / CORS / unreachable
    Logger.error('Network error - cannot reach server', 'API', err);
    throw new ApiError(0, 'Cannot reach server. Is the API running?');
  }

  let json;
  try { json = await res.json(); } catch (_) { json = {}; }

  if (!res.ok) {
    const msg = json?.message || json?.error || `HTTP ${res.status}`;
    Logger.warn(`${method} ${path} failed: ${msg}`, 'API', { status: res.status, response: json });
    throw new ApiError(res.status, msg);
  }

  Logger.success(`${method} ${path} ${res.status}`, 'API');
  return json?.data ?? json;
}

class ApiError extends Error {
  constructor(status, message) {
    super(message);
    this.status = status;
    this.name = 'ApiError';
  }
}

/* ══════════════════════════════════════════════════════════════════
   DOM REFS
   ══════════════════════════════════════════════════════════════════ */
const $ = id => document.getElementById(id);

const DOM = {
  // Header
  btnLogout:      $('btn-logout'),

  // Status bar
  statusBar:      $('status-bar'),
  statusText:     $('status-text'),

  // Views
  viewLogin:      $('view-login'),
  viewTasks:      $('view-tasks'),

  // Login form
  loginForm:      $('login-form'),
  loginEmail:     $('login-email'),
  loginPassword:  $('login-password'),
  rememberMe:     $('remember-me'),
  loginError:     $('login-error'),
  btnLogin:       $('btn-login'),

  // Tasks view
  userGreeting:   $('user-greeting'),
  searchInput:    $('search-input'),
  filterStatus:   $('filter-status'),
  taskListWrap:   $('task-list-wrap'),
  taskLoading:    $('task-loading'),
  taskEmpty:      $('task-empty'),
  taskList:       $('task-list'),

  // Add task modal
  addTaskModal:   $('add-task-modal'),
  btnToggleAdd:   $('btn-toggle-add'),
  btnCloseModal:  $('btn-close-modal'),
  addTaskForm:    $('add-task-form'),
  taskTitle:      $('task-title'),
  taskDesc:       $('task-desc'),
  taskPriority:   $('task-priority'),
  taskStatus:     $('task-status'),
  taskDueDate:    $('task-due-date'),
  addTaskError:   $('add-task-error'),
  btnCancelAdd:   $('btn-cancel-add'),
  btnAddTask:     $('btn-add-task'),
};

/* ══════════════════════════════════════════════════════════════════
   STATE
   ══════════════════════════════════════════════════════════════════ */
let _token = null;
let _user  = null;
let _tasks = [];           // raw from server
let _filterStatus = '';
let _searchQuery  = '';
let _debounceTimer = null;

/* ══════════════════════════════════════════════════════════════════
   STATUS BAR
   ══════════════════════════════════════════════════════════════════ */
let _statusTimeout = null;
/**
 * @param {string} msg
 * @param {'info'|'success'|'error'|'warning'} [type]
 * @param {number} [ms] auto-hide after ms (0 = permanent)
 */
function showStatus(msg, type = 'info', ms = 3500) {
  clearTimeout(_statusTimeout);
  DOM.statusBar.className = `status-bar ${type}`;
  DOM.statusText.textContent = msg;
  DOM.statusBar.hidden = false;
  if (ms > 0) _statusTimeout = setTimeout(() => { DOM.statusBar.hidden = true; }, ms);
}
function hideStatus() { clearTimeout(_statusTimeout); DOM.statusBar.hidden = true; }

/* ══════════════════════════════════════════════════════════════════
   SANITISE – prevent XSS when injecting into innerHTML
   ══════════════════════════════════════════════════════════════════ */
function esc(str) {
  if (str == null) return '';
  return String(str)
    .replace(/&/g, '&amp;')
    .replace(/</g, '&lt;')
    .replace(/>/g, '&gt;')
    .replace(/"/g, '&quot;')
    .replace(/'/g, '&#39;');
}

/* ══════════════════════════════════════════════════════════════════
   RENDER HELPERS
   ══════════════════════════════════════════════════════════════════ */
function renderLoggedOut() {
  DOM.viewLogin.hidden = false;
  DOM.viewTasks.hidden = true;
  DOM.btnLogout.hidden = true;
  hideStatus();
  DOM.loginForm.reset();
  DOM.loginError.hidden = true;
  setLoginBusy(false);
}

function renderLoggedIn() {
  DOM.viewLogin.hidden = true;
  DOM.viewTasks.hidden = false;
  DOM.btnLogout.hidden = false;
  setLoginBusy(false);  // Reset login button state

  const name = _user?.name || _user?.email?.split('@')[0] || 'there';
  DOM.userGreeting.innerHTML = `Hi, <strong>${esc(name)}!</strong> 👋`;

  loadTasks();
  loadMiniStats();
}

/* ══════════════════════════════════════════════════════════════════
   SPINNER / BUSY STATE HELPERS
   ══════════════════════════════════════════════════════════════════ */
function setLoginBusy(busy) {
  DOM.btnLogin.disabled = busy;
  DOM.btnLogin.querySelector('.btn-label').textContent = busy ? 'Signing in…' : 'Sign in';
  DOM.btnLogin.querySelector('.spinner').hidden = !busy;
}

function setAddTaskBusy(busy) {
  DOM.btnAddTask.disabled = busy;
  DOM.btnAddTask.querySelector('.btn-label').textContent = busy ? 'Adding…' : 'Add task';
  DOM.btnAddTask.querySelector('.spinner').hidden = !busy;
}

/* ══════════════════════════════════════════════════════════════════
   AUTH
   ══════════════════════════════════════════════════════════════════ */
async function login(email, password) {
  Logger.info(`Login attempt for: ${email}`, 'Auth');
  setLoginBusy(true);
  DOM.loginError.hidden = true;
  hideStatus();
  try {
    const data = await apiFetch('/api/auth/login', {
      method: 'POST',
      body: JSON.stringify({ email, password }),
    });
    // data = { accessToken, user }
    _token = data.accessToken;
    _user  = data.user;
    await storage.set(_token, _user);
    
    // Handle Remember Me
    const rememberMe = DOM.rememberMe.checked;
    await storage.setRememberMe(rememberMe, rememberMe ? email : '');
    Logger.info(`Remember me: ${rememberMe}`, 'Auth');
    
    Logger.success(`Login successful: ${_user.email}`, 'Auth');
    renderLoggedIn();
  } catch (err) {
    setLoginBusy(false);
    Logger.error(`Login failed for: ${email}`, 'Auth', err);
    const msg = err instanceof ApiError && err.status === 0
      ? err.message
      : (err.message || 'Login failed. Check your credentials.');
    DOM.loginError.textContent = msg;
    DOM.loginError.hidden = false;
    if (err.status === 0) showStatus(err.message, 'error', 0);
  }
}

async function logout() {
  Logger.info('User logging out', 'Auth');
  _token = null;
  _user  = null;
  _tasks = [];
  
  // Clear session but keep remember me settings
  await storage.clear();
  
  // Load remember me settings for next login
  const { rememberMe, email } = await storage.get();
  if (rememberMe && email) {
    DOM.loginEmail.value = email;
    DOM.rememberMe.checked = true;
  }
  
  renderLoggedOut();
  Logger.success('Logged out successfully', 'Auth');
}

/* ══════════════════════════════════════════════════════════════════
   TASKS – LOAD
   ══════════════════════════════════════════════════════════════════ */
async function loadTasks() {
  Logger.debug('Loading tasks', 'Tasks', { filterStatus: _filterStatus, searchQuery: _searchQuery });
  DOM.taskLoading.hidden = false;
  DOM.taskEmpty.hidden   = true;
  DOM.taskList.innerHTML = '';
  hideStatus();

  // Build query string
  const params = new URLSearchParams();
  if (_filterStatus) params.set('status', _filterStatus);
  if (_searchQuery)  params.set('search', _searchQuery);
  const qs = params.toString() ? `?${params}` : '';

  try {
    const data = await apiFetch(`/api/tasks${qs}`, {}, _token);
    // data = { tasks, count }
    _tasks = Array.isArray(data?.tasks) ? data.tasks : (Array.isArray(data) ? data : []);
    DOM.taskLoading.hidden = true;
    Logger.success(`Loaded ${_tasks.length} tasks`, 'Tasks');
    renderTaskList(_tasks);
  } catch (err) {
    DOM.taskLoading.hidden = true;
    Logger.error('Failed to load tasks', 'Tasks', err);
    const msg = err.status === 0
      ? err.message
      : `Failed to load tasks: ${err.message}`;
    showStatus(msg, 'error', err.status === 0 ? 0 : 5000);
    renderTaskList([]);
  }
}

/* ══════════════════════════════════════════════════════════════════
   TASKS – RENDER
   ══════════════════════════════════════════════════════════════════ */
const STATUS_LABELS = { todo: 'To do', in_progress: 'In progress', done: 'Done' };
const STATUS_TAGS   = { todo: 'tag-todo', in_progress: 'tag-inprog', done: 'tag-done' };
const STATUS_NEXT   = { todo: 'in_progress', in_progress: 'done', done: 'todo' };
const STATUS_NEXT_LABEL = { todo: '▶ Start', in_progress: '✓ Done', done: '↺ Reopen' };

function renderTaskList(tasks) {
  DOM.taskList.innerHTML = '';
  DOM.taskLoading.hidden = true;  // Always hide loading spinner

  if (!tasks.length) {
    DOM.taskEmpty.hidden = false;
    return;
  }
  DOM.taskEmpty.hidden = true;

  const frag = document.createDocumentFragment();
  tasks.forEach(task => {
    const li = buildTaskItem(task);
    frag.appendChild(li);
  });
  DOM.taskList.appendChild(frag);
}

function buildTaskItem(task) {
  const status   = task.status || 'todo';
  const isDone   = status === 'done';
  const tagClass = STATUS_TAGS[status] || 'tag-todo';
  const nextLbl  = STATUS_NEXT_LABEL[status] || '▶ Start';

  const li = document.createElement('li');
  li.className = `task-item${isDone ? ' done' : ''}${task.priority === 'high' ? ' high-priority' : ''}`;
  li.dataset.id = task._id || task.id;

  const priorityIcon = task.priority === 'high' ? '🔴' : task.priority === 'low' ? '🟢' : '🟡';

  li.innerHTML = `
    <input type="checkbox" class="task-checkbox" title="Toggle done"
           ${isDone ? 'checked' : ''} data-action="toggle" />
    <div class="task-body">
      <div class="task-title">${esc(task.title)}</div>
      ${task.description ? `<div class="task-desc">${esc(task.description)}</div>` : ''}
      <div class="task-meta">
        <span class="priority-icon" title="${task.priority || 'medium'} priority">${priorityIcon}</span>
        <span class="tag ${tagClass}">${esc(STATUS_LABELS[status] || status)}</span>
        ${task.dueDate ? `<span class="due-date">📅 ${formatDueDate(task.dueDate)}</span>` : ''}
      </div>
      <div class="task-actions">
        ${!isDone
          ? `<button class="btn-icon-sm" data-action="next-status" title="Advance status">${esc(nextLbl)}</button>`
          : ''
        }
        <button class="btn-icon-sm" data-action="edit" title="Edit task">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <path d="M11 4H4a2 2 0 0 0-2 2v14a2 2 0 0 0 2 2h14a2 2 0 0 0 2-2v-7"/>
            <path d="M18.5 2.5a2.121 2.121 0 0 1 3 3L12 15l-4 1 1-4 9.5-9.5z"/>
          </svg>
        </button>
        <button class="btn-icon-sm btn-danger" data-action="trash" title="Move to trash">
          <svg viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round">
            <polyline points="3 6 5 6 21 6"/><path d="M19 6v14a2 2 0 0 1-2 2H7a2 2 0 0 1-2-2V6m3 0V4a2 2 0 0 1 2-2h4a2 2 0 0 1 2 2v2"/>
          </svg>
        </button>
      </div>
    </div>`;

  // Events
  const checkbox = li.querySelector('[data-action="toggle"]');
  checkbox.addEventListener('change', () => toggleTaskDone(task));

  const nextBtn = li.querySelector('[data-action="next-status"]');
  if (nextBtn) nextBtn.addEventListener('click', () => advanceTaskStatus(task));

  const editBtn = li.querySelector('[data-action="edit"]');
  if (editBtn) editBtn.addEventListener('click', () => editTask(task));

  const trashBtn = li.querySelector('[data-action="trash"]');
  if (trashBtn) trashBtn.addEventListener('click', () => trashTask(task));

  return li;
}

function formatDueDate(dateStr) {
  try {
    const date = new Date(dateStr);
    const now = new Date();
    const diffMs = date - now;
    const diffDays = Math.ceil(diffMs / (1000 * 60 * 60 * 24));
    
    if (diffDays < 0) return `Overdue`;
    if (diffDays === 0) return `Today`;
    if (diffDays === 1) return `Tomorrow`;
    if (diffDays <= 7) return `${diffDays} days`;
    return date.toLocaleDateString();
  } catch (_) {
    return dateStr;
  }
}

/* ══════════════════════════════════════════════════════════════════
   TASKS – CREATE
   ══════════════════════════════════════════════════════════════════ */
async function addTask(title, description, priority = 'medium', status = 'todo', dueDate = null) {
  Logger.info(`Creating task: ${title}`, 'Tasks', { priority, status });
  setAddTaskBusy(true);
  DOM.addTaskError.hidden = true;
  hideStatus();
  try {
    const body = { title, status, priority };
    if (description) body.description = description;
    if (dueDate) body.dueDate = new Date(dueDate).toISOString();
    
    await apiFetch('/api/tasks', {
      method: 'POST',
      body: JSON.stringify(body),
    }, _token);
    Logger.success(`Task created: ${title}`, 'Tasks');
    showStatus('Task added!', 'success', 2500);
    closeAddTaskModal();
    await loadTasks();
    await loadMiniStats(); // Refresh stats
  } catch (err) {
    setAddTaskBusy(false);
    Logger.error('Failed to create task', 'Tasks', err);
    DOM.addTaskError.textContent = err.message || 'Failed to add task.';
    DOM.addTaskError.hidden = false;
  }
}

/* ══════════════════════════════════════════════════════════════════
   TASKS – UPDATE
   ══════════════════════════════════════════════════════════════════ */
async function updateTask(taskId, title, description, priority, status, dueDate) {
  Logger.info(`Updating task: ${taskId}`, 'Tasks', { title, priority, status });
  setAddTaskBusy(true);
  DOM.addTaskError.hidden = true;
  hideStatus();
  try {
    const body = { title, status, priority };
    if (description) body.description = description;
    if (dueDate) body.dueDate = new Date(dueDate).toISOString();
    
    await apiFetch(`/api/tasks/${taskId}`, {
      method: 'PATCH',
      body: JSON.stringify(body),
    }, _token);
    Logger.success(`Task updated: ${title}`, 'Tasks');
    showStatus('Task updated!', 'success', 2500);
    closeAddTaskModal();
    await loadTasks();
    await loadMiniStats();
  } catch (err) {
    setAddTaskBusy(false);
    Logger.error('Failed to update task', 'Tasks', err);
    DOM.addTaskError.textContent = err.message || 'Failed to update task.';
    DOM.addTaskError.hidden = false;
  }
}

/* ══════════════════════════════════════════════════════════════════
   TASKS – EDIT
   ══════════════════════════════════════════════════════════════════ */
function editTask(task) {
  Logger.info(`Opening edit modal for task: ${task.title}`, 'Tasks');
  
  // Populate form with existing task data
  DOM.taskTitle.value = task.title || '';
  DOM.taskDesc.value = task.description || '';
  DOM.taskPriority.value = task.priority || 'medium';
  DOM.taskStatus.value = task.status || 'todo';
  
  // Convert ISO date to datetime-local format
  if (task.dueDate) {
    const date = new Date(task.dueDate);
    const localDate = new Date(date.getTime() - date.getTimezoneOffset() * 60000);
    DOM.taskDueDate.value = localDate.toISOString().slice(0, 16);
  } else {
    DOM.taskDueDate.value = '';
  }
  
  // Store task ID for update
  DOM.addTaskForm.dataset.editingId = task._id || task.id;
  
  // Change modal title and button text
  const modalHeader = DOM.addTaskModal.querySelector('.modal-header h3');
  if (modalHeader) modalHeader.textContent = 'Edit Task';
  DOM.btnAddTask.querySelector('.btn-label').textContent = 'Update Task';
  
  // Open modal
  DOM.addTaskModal.hidden = false;
  DOM.addTaskError.hidden = true;
  setTimeout(() => DOM.taskTitle.focus(), 100);
}

/* ══════════════════════════════════════════════════════════════════
   TASKS – TRASH
   ══════════════════════════════════════════════════════════════════ */
async function trashTask(task) {
  const taskId = task._id || task.id;
  Logger.info(`Trashing task: ${task.title}`, 'Tasks', { taskId });
  try {
    await apiFetch(`/api/tasks/${taskId}/trash`, {
      method: 'PATCH',
    }, _token);
    Logger.success(`Task trashed: ${task.title}`, 'Tasks');
    showStatus('Task moved to trash', 'success', 2000);
    await loadTasks();
    await loadMiniStats();
  } catch (err) {
    Logger.error('Failed to trash task', 'Tasks', err);
    showStatus(`Failed to trash: ${err.message}`, 'error', 4000);
  }
}

/* ══════════════════════════════════════════════════════════════════
   TASKS – UPDATE STATUS
   ══════════════════════════════════════════════════════════════════ */
async function updateTaskStatus(task, newStatus) {
  const taskId = task._id || task.id;
  Logger.info(`Updating task status: ${task.title}`, 'Tasks', { from: task.status, to: newStatus });
  try {
    await apiFetch(`/api/tasks/${taskId}`, {
      method: 'PATCH',
      body: JSON.stringify({ status: newStatus }),
    }, _token);
    // Optimistically update local state
    task.status = newStatus;
    // Re-render only the specific item
    const li = DOM.taskList.querySelector(`[data-id="${CSS.escape(String(taskId))}"]`);
    if (li) {
      const replacement = buildTaskItem(task);
      li.replaceWith(replacement);
    }
    Logger.success(`Task status updated: ${task.title} → ${newStatus}`, 'Tasks');
    showStatus(`Task marked as "${STATUS_LABELS[newStatus] || newStatus}"`, 'success', 2000);
    await loadMiniStats(); // Refresh stats
  } catch (err) {
    Logger.error('Failed to update task status', 'Tasks', err);
    showStatus(`Update failed: ${err.message}`, 'error', 4000);
    // Revert checkbox visually by re-rendering
    await loadTasks();
  }
}

async function toggleTaskDone(task) {
  const newStatus = task.status === 'done' ? 'todo' : 'done';
  await updateTaskStatus(task, newStatus);
}

async function advanceTaskStatus(task) {
  const newStatus = STATUS_NEXT[task.status] || 'done';
  await updateTaskStatus(task, newStatus);
}

/* ══════════════════════════════════════════════════════════════════
   MINI DASHBOARD STATS
   ══════════════════════════════════════════════════════════════════ */
async function loadMiniStats() {
  Logger.debug('Loading dashboard stats', 'Stats');
  try {
    const data = await apiFetch('/api/tasks/stats', {}, _token);
    const stats = data?.stats || data;
    Logger.success('Dashboard stats loaded', 'Stats', stats);
    renderMiniStats(stats);
  } catch (err) {
    // Silently fail - stats are optional
    Logger.warn('Failed to load stats (optional)', 'Stats');
  }
}

function renderMiniStats(stats) {
  const container = document.getElementById('mini-stats');
  if (!container) return;

  const total = stats.total || 0;
  const done = stats.byStatus?.done || 0;
  const overdue = stats.overdue || 0;
  const streak = stats.streak || 0;
  const completion = total > 0 ? Math.round((done / total) * 100) : 0;

  container.innerHTML = `
    <div class="stat-item">
      <span class="stat-value">${done}/${total}</span>
      <span class="stat-label">Done</span>
    </div>
    <div class="stat-item">
      <span class="stat-value ${overdue > 0 ? 'overdue' : ''}">${overdue}</span>
      <span class="stat-label">Overdue</span>
    </div>
    <div class="stat-item">
      <span class="stat-value streak">${streak}🔥</span>
      <span class="stat-label">Streak</span>
    </div>
    <div class="stat-item">
      <span class="stat-value">${completion}%</span>
      <span class="stat-label">Complete</span>
    </div>
  `;
  container.hidden = false;
}

/* ══════════════════════════════════════════════════════════════════
   MODAL TOGGLE
   ══════════════════════════════════════════════════════════════════ */
function openAddTaskModal() {
  DOM.addTaskModal.hidden = false;
  DOM.addTaskForm.reset();
  DOM.addTaskError.hidden = true;
  setAddTaskBusy(false);
  
  // Reset to "add" mode
  delete DOM.addTaskForm.dataset.editingId;
  const modalHeader = DOM.addTaskModal.querySelector('.modal-header h3');
  if (modalHeader) modalHeader.textContent = 'New Task';
  DOM.btnAddTask.querySelector('.btn-label').textContent = 'Create Task';
  
  setTimeout(() => DOM.taskTitle.focus(), 100);
}

function closeAddTaskModal() {
  DOM.addTaskModal.hidden = true;
  DOM.addTaskForm.reset();
  DOM.addTaskError.hidden = true;
  setAddTaskBusy(false);
  delete DOM.addTaskForm.dataset.editingId;
}

/* ══════════════════════════════════════════════════════════════════
   EVENT BINDINGS
   ══════════════════════════════════════════════════════════════════ */
function bindEvents() {
  // Login form
  DOM.loginForm.addEventListener('submit', e => {
    e.preventDefault();
    const email    = DOM.loginEmail.value.trim();
    const password = DOM.loginPassword.value;
    if (!email || !password) return;
    login(email, password);
  });

  // Logout
  DOM.btnLogout.addEventListener('click', logout);

  // Search (debounced)
  DOM.searchInput.addEventListener('input', () => {
    clearTimeout(_debounceTimer);
    _debounceTimer = setTimeout(() => {
      _searchQuery = DOM.searchInput.value.trim();
      loadTasks();
    }, 350);
  });

  // Filter
  DOM.filterStatus.addEventListener('change', () => {
    _filterStatus = DOM.filterStatus.value;
    loadTasks();
  });

  // Toggle add modal
  DOM.btnToggleAdd.addEventListener('click', openAddTaskModal);
  DOM.btnCloseModal.addEventListener('click', closeAddTaskModal);
  DOM.btnCancelAdd.addEventListener('click', closeAddTaskModal);

  // Close modal on backdrop click
  DOM.addTaskModal.addEventListener('click', e => {
    if (e.target === DOM.addTaskModal || e.target.classList.contains('modal-backdrop')) {
      closeAddTaskModal();
    }
  });

  // Add task form
  DOM.addTaskForm.addEventListener('submit', e => {
    e.preventDefault();
    const title = DOM.taskTitle.value.trim();
    const desc = DOM.taskDesc.value.trim();
    const priority = DOM.taskPriority.value;
    const status = DOM.taskStatus.value;
    const dueDate = DOM.taskDueDate.value;
    
    if (!title) {
      DOM.addTaskError.textContent = 'Title is required.';
      DOM.addTaskError.hidden = false;
      DOM.taskTitle.focus();
      return;
    }
    
    // Check if editing existing task
    const editingId = DOM.addTaskForm.dataset.editingId;
    if (editingId) {
      updateTask(editingId, title, desc, priority, status, dueDate);
    } else {
      addTask(title, desc, priority, status, dueDate);
    }
  });
}

/* ══════════════════════════════════════════════════════════════════
   INIT
   ══════════════════════════════════════════════════════════════════ */
async function init() {
  Logger.info('Initializing FocusTrail Extension', 'Init');
  bindEvents();

  const { token, user, rememberMe, email } = await storage.get();
  if (token) {
    Logger.info('Existing session found', 'Init', { email: user?.email });
    _token = token;
    _user  = user;
    renderLoggedIn();
  } else {
    Logger.info('No existing session - showing login', 'Init');
    
    // Load remembered email if available
    if (rememberMe && email) {
      DOM.loginEmail.value = email;
      DOM.rememberMe.checked = true;
      Logger.debug('Loaded remembered email', 'Init', { email });
    }
    
    renderLoggedOut();
  }
  Logger.success('Extension ready', 'Init');
}

document.addEventListener('DOMContentLoaded', init);
