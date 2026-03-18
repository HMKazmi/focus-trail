# FocusTrail Chrome Extension

> A modern Chrome extension for task management with offline capabilities

![Chrome](https://img.shields.io/badge/Chrome-Extension-4285F4?logo=googlechrome)
![Manifest](https://img.shields.io/badge/Manifest-V3-green)
![JavaScript](https://img.shields.io/badge/JavaScript-ES6+-F7DF1E?logo=javascript)

## 🎯 Overview

The FocusTrail Chrome Extension brings powerful task management directly to your browser. Manage your tasks without leaving your current tab, with a beautiful popup interface and full synchronization with the mobile app and backend.

## ✨ Features

### Task Management
- **Quick Access**: Manage tasks from browser toolbar
- **Full CRUD**: Create, read, update, delete tasks
- **Priority Levels**: Low, Medium, High with visual indicators
- **Status Tracking**: To Do, In Progress, Done
- **Due Dates**: Set and track deadlines
- **Search & Filter**: Find tasks quickly
- **Task Actions**: Edit, advance status, or delete with one click

### User Experience
- **Clean UI**: Modern glassmorphism design
- **Compact Design**: Optimized for extension popup (400x600px)
- **Real-time Updates**: Instant feedback on all actions
- **Dashboard Stats**: View productivity metrics at a glance
- **Remember Me**: Stay logged in across sessions
- **Offline Support**: Queue operations when offline

### UI Components
- User greeting with quick stats
- Comprehensive task modal with all fields
- Action buttons on each task
- Loading states and animations
- Error handling with user-friendly messages

## 🏗️ Architecture

```
extension/
├── icons/              # Extension icons (16, 48, 128px)
├── config.js          # Configuration (API URL, log level)
├── logger.js          # Comprehensive logging system
├── popup.html         # Extension popup UI
├── popup.css          # Styles (glassmorphism theme)
├── popup.js           # Application logic
├── manifest.json      # Extension manifest V3
└── README.md          # This file
```

### Key Components

**popup.js Structure:**
```javascript
// Configuration & Initialization
// Storage API (Chrome local storage)
// API Client (Fetch with error handling)
// DOM References
// Authentication (Login/Logout)
// Task CRUD Operations
// Modal Management
// Event Bindings
```

## 🛠️ Tech Stack

| Component | Technology |
|-----------|-----------|
| Manifest | V3 |
| UI | HTML5 + CSS3 |
| Logic | Vanilla JavaScript (ES6+) |
| Storage | Chrome Storage API |
| API | REST (Fetch API) |
| Logging | Custom Winston-style logger |

## 🚀 Getting Started

### Prerequisites

- Google Chrome browser
- FocusTrail backend running
- Node.js (for icon generation only)

### Installation

#### Development Setup

1. **Clone the repository**
   ```bash
   git clone https://github.com/yourusername/FocusTrail.git
   cd FocusTrail/extension
   ```

2. **Configure the extension**
   
   Edit `config.js`:
   ```javascript
   const CONFIG = {
     API_BASE_URL: 'http://localhost:4000',  // Your API URL
     LOG_LEVEL: 'info',  // debug | info | warn | error
   };
   ```

3. **Generate icons** (if needed)
   ```bash
   npm install
   node generate-icons.js
   ```

4. **Load in Chrome**
   - Open Chrome and go to `chrome://extensions/`
   - Enable "Developer mode" (top right)
   - Click "Load unpacked"
   - Select the `extension` folder
   - Extension icon appears in toolbar

#### Production Setup

For production, update the API URL to your production server:
```javascript
const CONFIG = {
  API_BASE_URL: 'https://api.focustrail.com',
  LOG_LEVEL: 'warn',  // Reduce logging in production
};
```

## 📱 Features in Detail

### Task Creation Modal

The extension includes a comprehensive task creation modal with:

- **Title** (required): Task name
- **Description** (optional): Detailed notes
- **Priority**: Low/Medium/High with emoji indicators
- **Status**: To Do/In Progress/Done
- **Due Date**: Date/time picker

### Task List View

Each task displays:
- Checkbox for quick completion toggle
- Title and description
- Priority indicator (🔴🟡🟢)
- Status badge
- Due date (if set)
- Action buttons:
  - **Advance Status**: Quick status progression
  - **Edit**: Open modal with prefilled data
  - **Delete**: Move to trash

### Dashboard Stats

Mini dashboard showing:
- Tasks completed / total
- Overdue count (highlighted in red)
- Productivity streak
- Completion percentage

## 🔧 Configuration

### config.js Options

```javascript
const CONFIG = {
  // API endpoint
  API_BASE_URL: 'http://localhost:4000',
  
  // Logging level
  LOG_LEVEL: 'info',  // Controls console verbosity
};
```

### Logging Levels

- **debug**: All operations (API calls, state changes)
- **info**: Important operations (login, task creation) - Default
- **warn**: Warnings and non-critical errors
- **error**: Critical errors only

### Manifest Permissions

```json
{
  "permissions": [
    "storage"           // Chrome storage API
  ],
  "host_permissions": [
    "http://localhost:4000/*",  // Your API domain
    "https://api.focustrail.com/*"
  ]
}
```

## 🎨 Styling

The extension uses a modern glassmorphism theme:

```css
/* Primary Colors */
--accent: #6366F1      /* Indigo */
--accent-hover: #818CF8

/* Backgrounds */
--bg-card: rgba(255, 255, 255, 0.05)
--backdrop: backdrop-filter: blur(10px)

/* Text */
--text: #E5E7EB
--text-muted: #9CA3AF
```

### Customization

Edit `popup.css` to customize:
- Colors and theme
- Layout and spacing
- Animations and transitions
- Card styles

## 📊 Chrome Storage

The extension uses Chrome's local storage:

```javascript
// Stored data
{
  ft_token: 'JWT token',
  ft_user: { email, name },
  ft_remember_me: boolean,
  ft_email: 'saved email'
}
```

## 🔐 Security

### Authentication
- JWT tokens stored in Chrome storage
- Tokens sent in Authorization header
- Auto-logout on token expiration

### Data Privacy
- All data stored locally in Chrome
- No analytics or tracking
- Secure communication with backend

### CORS Handling
- Backend configured to allow extension origin
- Credentials included in requests

## 🐛 Debugging

### Enable Debug Logging

```javascript
// config.js
const CONFIG = {
  LOG_LEVEL: 'debug',  // Enable all logs
};
```

### View Logs

1. Right-click extension icon
2. Select "Inspect popup"
3. Open Console tab
4. See color-coded logs with timestamps

### Log Format

```
2026-03-18T10:30:15.123Z ℹ️ INFO [Auth] Login attempt for: user@example.com
2026-03-18T10:30:15.456Z ✅ SUCCESS [Auth] Login successful
2026-03-18T10:30:15.789Z 🌐 API POST /api/auth/login 200
```

### Common Issues

**Issue**: Extension won't load
```
Solution: Check manifest.json for errors
         Reload extension in chrome://extensions
         Check browser console for errors
```

**Issue**: API calls failing
```
Solution: Verify API_BASE_URL in config.js
         Check backend is running
         Verify CORS settings on backend
         Check host_permissions in manifest.json
```

**Issue**: Login not working
```
Solution: Check credentials
         Verify backend auth endpoint
         Check browser console for errors
         Ensure Remember Me data is cleared if needed
```

## 📦 Distribution

### Preparing for Chrome Web Store

1. **Update manifest**
   ```json
   {
     "version": "1.0.0",
     "name": "FocusTrail",
     "description": "Productivity task manager",
     "icons": {
       "16": "icons/icon16.png",
       "48": "icons/icon48.png",
       "128": "icons/icon128.png"
     }
   }
   ```

2. **Test thoroughly**
   - All features working
   - No console errors
   - Performance optimized
   - UI responsive

3. **Create screenshots**
   - 1280x800 or 640x400
   - Show key features
   - Clean and professional

4. **Package extension**
   ```bash
   zip -r focustrail-extension.zip extension/ -x "*.git*" "node_modules/*"
   ```

5. **Submit to Chrome Web Store**
   - Create developer account
   - Upload ZIP file
   - Fill in store listing
   - Submit for review

## 🔄 Updates

### Version Management

Update version in `manifest.json`:
```json
{
  "version": "1.0.1",  // Major.Minor.Patch
  "version_name": "1.0.1 Beta"
}
```

### Auto-Update

Chrome Web Store handles updates automatically:
- Users get updates within hours
- No action required from users

## 📈 Performance

### Optimization Tips

- Minimize DOM manipulations
- Use event delegation
- Lazy load images
- Cache API responses
- Debounce search input

### Bundle Size

Current extension size: ~50KB
- HTML: ~8KB
- CSS: ~15KB
- JavaScript: ~25KB
- Icons: ~2KB

## 🧪 Testing

### Manual Testing Checklist

- [ ] Login with correct credentials
- [ ] Login with incorrect credentials
- [ ] Remember Me functionality
- [ ] Create new task
- [ ] Edit existing task
- [ ] Change task status
- [ ] Delete task
- [ ] Search tasks
- [ ] Filter by status
- [ ] Dashboard stats update
- [ ] Logout

### Browser Compatibility

Tested on:
- Chrome 120+
- Edge 120+ (Chromium-based)

## 🤝 Contributing

1. Follow existing code style
2. Test all changes
3. Update documentation
4. Keep commits focused
5. No console.log() in production

## 📄 Files Description

| File | Purpose |
|------|---------|
| `manifest.json` | Extension configuration |
| `popup.html` | UI structure |
| `popup.css` | Styles and theming |
| `popup.js` | Application logic |
| `config.js` | User configuration |
| `logger.js` | Logging utility |
| `icons/` | Extension icons |

## 🎯 Future Enhancements

- [ ] Keyboard shortcuts
- [ ] Context menu integration
- [ ] Browser notifications
- [ ] Multiple account support
- [ ] Import/Export tasks
- [ ] Themes (light/dark)
- [ ] Offline queue sync

## 📄 License

This project is part of FocusTrail and is licensed under the MIT License.

---

For issues and questions, please refer to the main repository README.


---

## Loading the extension (unpacked)

1. Open Chrome and navigate to `chrome://extensions`.
2. Enable **Developer mode** (toggle in the top-right corner).
3. Click **Load unpacked**.
4. Select this `extension/` folder.
5. The FocusTrail icon appears in the toolbar — click it to open the popup.

---

## Generating real icons

The included icons are 1×1 transparent placeholders.  
To produce proper icons:

```bash
# Option A – with node-canvas
npm install canvas
node generate-icons.js

# Option B – design your own
# Export a square logo at 16px, 48px and 128px,
# name the files icon16.png / icon48.png / icon128.png,
# and drop them into the icons/ folder.
```

After replacing icons, reload the extension on `chrome://extensions`.

---

## API endpoints used

| Method | Path | Purpose |
|--------|------|---------|
| `POST` | `/api/auth/login` | Obtain `accessToken` |
| `GET`  | `/api/tasks` | List tasks (supports `?status=` & `?search=`) |
| `POST` | `/api/tasks` | Create a task |
| `PATCH`| `/api/tasks/:id` | Update task status |

The JWT is stored in `chrome.storage.local` and attached as `Authorization: Bearer <token>` on every authenticated request.

---

## Server CORS configuration

Chrome extension popups send requests with a `null` origin (not `chrome-extension://…`).  
Add `null` to the server's `CORS_ORIGINS` environment variable so the API accepts extension requests:

```env
# .env (server)
CORS_ORIGINS=http://localhost:3000,null
PORT=4000
```

> Alternatively, update `app.ts` to also allow `null` origin explicitly in the CORS callback.

---

## Development tips

- After editing any file, go to `chrome://extensions` and click the **↺ reload** icon next to FocusTrail.
- Open **DevTools → Sources → Content scripts** (or right-click the popup → Inspect) to debug `popup.js`.
- The server must have CORS configured to allow requests from `chrome-extension://*` or from `null` origin (which is what extension popups send).
