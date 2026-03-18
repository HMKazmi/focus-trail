/* ═══════════════════════════════════════════════════════════════
   FocusTrail – popup.js
   ═══════════════════════════════════════════════════════════════ */
'use strict';

/* ── Config (injected by config.js before this script) ─────────── */
const BASE_URL = (typeof CONFIG !== 'undefined' && CONFIG.API_BASE_URL)
  ? CONFIG.API_BASE_URL.replace(/\/$/, '')
  : 'http://localhost:4000';

/* ══════════════════════════════════════════════════════════════════
   STORAGE HELPERS
   ══════════════════════════════════════════════════════════════════ */
const storage = {
  /** @returns {Promise<{token:string|null, user:object|null}>} */
  get() {
    return new Promise(resolve =>
      chrome.storage.local.get(['ft_token', 'ft_user'], data =>
        resolve({ token: data.ft_token || null, user: data.ft_user || null })
      )
    );
  },
  /** @param {string} token @param {object} user */
  set(token, user) {
    return new Promise(resolve =>
      chrome.storage.local.set({ ft_token: token, ft_user: user }, resolve)
    );
  },
  clear() {
    return new Promise(resolve =>
      chrome.storage.local.remove(['ft_token', 'ft_user'], resolve)
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

  let res;
  try {
    res = await fetch(url, { ...opts, headers });
  } catch (_) {
    // Network / CORS / unreachable
    throw new ApiError(0, 'Cannot reach server. Is the API running?');
  }

  let json;
  try { json = await res.json(); } catch (_) { json = {}; }

  if (!res.ok) {
    const msg = json?.message || json?.error || `HTTP ${res.status}`;
    throw new ApiError(res.status, msg);
  }

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

  // Add task
  btnToggleAdd:   $('btn-toggle-add'),
  addTaskForm:    $('add-task-form'),
  taskTitle:      $('task-title'),
  taskDesc:       $('task-desc'),
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

  const name = _user?.name || _user?.email?.split('@')[0] || 'there';
  DOM.userGreeting.innerHTML = `Hey, <strong>${esc(name)}</strong> 👋`;

  loadTasks();
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
    renderLoggedIn();
  } catch (err) {
    setLoginBusy(false);
    const msg = err instanceof ApiError && err.status === 0
      ? err.message
      : (err.message || 'Login failed. Check your credentials.');
    DOM.loginError.textContent = msg;
    DOM.loginError.hidden = false;
    if (err.status === 0) showStatus(err.message, 'error', 0);
  }
}

async function logout() {
  _token = null;
  _user  = null;
  _tasks = [];
  await storage.clear();
  renderLoggedOut();
}

/* ══════════════════════════════════════════════════════════════════
   TASKS – LOAD
   ══════════════════════════════════════════════════════════════════ */
async function loadTasks() {
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
    renderTaskList(_tasks);
  } catch (err) {
    DOM.taskLoading.hidden = true;
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
  li.className = `task-item${isDone ? ' done' : ''}`;
  li.dataset.id = task._id || task.id;

  li.innerHTML = `
    <input type="checkbox" class="task-checkbox" title="Toggle done"
           ${isDone ? 'checked' : ''} data-action="toggle" />
    <div class="task-body">
      <div class="task-title">${esc(task.title)}</div>
      ${task.description ? `<div class="task-desc">${esc(task.description)}</div>` : ''}
      <div class="task-meta">
        <span class="tag ${tagClass}">${esc(STATUS_LABELS[status] || status)}</span>
        ${!isDone
          ? `<button class="btn-status" data-action="next-status" title="Advance status">${esc(nextLbl)}</button>`
          : ''
        }
      </div>
    </div>`;

  // Events
  const checkbox = li.querySelector('[data-action="toggle"]');
  checkbox.addEventListener('change', () => toggleTaskDone(task));

  const nextBtn = li.querySelector('[data-action="next-status"]');
  if (nextBtn) nextBtn.addEventListener('click', () => advanceTaskStatus(task));

  return li;
}

/* ══════════════════════════════════════════════════════════════════
   TASKS – CREATE
   ══════════════════════════════════════════════════════════════════ */
async function addTask(title, description) {
  setAddTaskBusy(true);
  DOM.addTaskError.hidden = true;
  hideStatus();
  try {
    const body = { title, status: 'todo' };
    if (description) body.description = description;
    await apiFetch('/api/tasks', {
      method: 'POST',
      body: JSON.stringify(body),
    }, _token);
    showStatus('Task added!', 'success', 2500);
    collapseAddForm();
    DOM.addTaskForm.reset();
    await loadTasks();
  } catch (err) {
    setAddTaskBusy(false);
    DOM.addTaskError.textContent = err.message || 'Failed to add task.';
    DOM.addTaskError.hidden = false;
  }
}

/* ══════════════════════════════════════════════════════════════════
   TASKS – UPDATE STATUS
   ══════════════════════════════════════════════════════════════════ */
async function updateTaskStatus(task, newStatus) {
  const taskId = task._id || task.id;
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
    showStatus(`Task marked as "${STATUS_LABELS[newStatus] || newStatus}"`, 'success', 2000);
  } catch (err) {
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
   ADD FORM TOGGLE
   ══════════════════════════════════════════════════════════════════ */
function expandAddForm() {
  DOM.addTaskForm.classList.replace('collapsed', 'expanded');
  DOM.btnToggleAdd.hidden = true;
  DOM.taskTitle.focus();
}

function collapseAddForm() {
  DOM.addTaskForm.classList.replace('expanded', 'collapsed');
  DOM.btnToggleAdd.hidden = false;
  DOM.addTaskError.hidden = true;
  setAddTaskBusy(false);
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

  // Toggle add form
  DOM.btnToggleAdd.addEventListener('click', expandAddForm);
  DOM.btnCancelAdd.addEventListener('click', collapseAddForm);

  // Add task form
  DOM.addTaskForm.addEventListener('submit', e => {
    e.preventDefault();
    const title = DOM.taskTitle.value.trim();
    const desc  = DOM.taskDesc.value.trim();
    if (!title) {
      DOM.addTaskError.textContent = 'Title is required.';
      DOM.addTaskError.hidden = false;
      DOM.taskTitle.focus();
      return;
    }
    addTask(title, desc);
  });
}

/* ══════════════════════════════════════════════════════════════════
   INIT
   ══════════════════════════════════════════════════════════════════ */
async function init() {
  bindEvents();

  const { token, user } = await storage.get();
  if (token) {
    _token = token;
    _user  = user;
    renderLoggedIn();
  } else {
    renderLoggedOut();
  }
}

document.addEventListener('DOMContentLoaded', init);
