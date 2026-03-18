# FocusTrail – Chrome Extension

A Manifest V3 Chrome extension that lets you manage your **FocusTrail** tasks directly from the browser toolbar — no page reload needed.

---

## Features

| Feature | Details |
|---------|---------|
| 🔐 Login / Logout | Email + password auth against the Express API |
| 📋 Task list | View all tasks with status badges, search & filter |
| ➕ Add task | Title + optional description, instant feedback |
| ✅ Mark done | Checkbox toggle or status-cycle button (To do → In progress → Done) |
| 🌐 Offline guard | Friendly "Cannot reach server" message when API is unreachable |
| 🎨 Modern UI | Dark glassmorphism theme, micro-animations, loading spinner |

---

## File structure

```
extension/
├── manifest.json        ← MV3 manifest
├── popup.html           ← Popup UI
├── popup.css            ← Styles (dark glassmorphism)
├── popup.js             ← All logic (auth, tasks, DOM)
├── config.js            ← API_BASE_URL configuration
├── generate-icons.js    ← Helper script to create placeholder icons
└── icons/
    ├── icon16.png
    ├── icon48.png
    └── icon128.png
```

---

## Configuration

Open `config.js` and set `API_BASE_URL` to point at your server:

```js
const CONFIG = {
  API_BASE_URL: 'http://localhost:4000',   // ← change this if needed
};
```

> If you run the API on a different host or port, update the value **and** the
> `host_permissions` array inside `manifest.json` to match, otherwise Chrome
> will block the requests.

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
