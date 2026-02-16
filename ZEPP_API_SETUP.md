# ZeppOS Watch App + REST API — Complete Setup Guide

> **Purpose:** This document captures every detail needed to build a ZeppOS watch app that connects to a REST API (Directus in our case). It is written for AI agents and developers who need to recreate this app or build a new one from scratch. Every gotcha, bug, and non-obvious behavior discovered during development is documented here.

---

## Table of Contents

1. [Overview](#1-overview)
2. [Prerequisites & Tooling](#2-prerequisites--tooling)
3. [Project Structure](#3-project-structure)
4. [app.json Configuration (v3 Format)](#4-appjson-configuration-v3-format)
5. [ZML Framework Deep Dive](#5-zml-framework-deep-dive)
6. [BLE Communication Architecture](#6-ble-communication-architecture)
7. [Connecting to a REST API](#7-connecting-to-a-rest-api)
8. [Settings Page (Companion App)](#8-settings-page-companion-app)
9. [Watch UI Patterns](#9-watch-ui-patterns)
10. [Bugs & Gotchas (Lessons Learned)](#10-bugs--gotchas-lessons-learned)
11. [Build, Deploy & Debug](#11-build-deploy--debug)
12. [Complete Code Reference](#12-complete-code-reference)

---

## 1. Overview

**TaskIt** is a ZeppOS watch companion app for a Flutter-based todo/habits application. It runs on Amazfit watches (tested on Amazfit Bip 6, 390x450 square screen) and communicates with a Directus CMS backend over HTTP through the phone's internet connection.

### Architecture at a Glance

```
┌─────────────┐      BLE       ┌──────────────┐     HTTPS     ┌──────────────┐
│  Watch App  │ ←────────────→ │  Phone Side  │ ←───────────→ │  Directus    │
│  (BasePage) │   ZML jsonrpc  │   Service    │   this.fetch  │  REST API    │
│             │                │(BaseSideServ)│               │              │
└─────────────┘                └──────────────┘               └──────────────┘
                                      ↕
                               ┌──────────────┐
                               │  Settings    │
                               │  Page        │
                               │(AppSettings) │
                               └──────────────┘
```

**Three runtime contexts:**
1. **Device (Watch)** — Runs on the watch hardware. Uses `@zos/ui`, `@zos/router`, etc. No internet access.
2. **Side Service (Phone)** — Runs on the paired phone via the Zepp companion app. Has internet access via `this.fetch()`. Communicates with watch over BLE.
3. **Settings Page (Phone)** — UI rendered in the Zepp companion app's settings panel. Can read/write `settingsStorage`.

---

## 2. Prerequisites & Tooling

### Required Software

| Tool | Purpose | Install |
|------|---------|---------|
| **Node.js** (v16+) | JavaScript runtime | nodejs.org |
| **npm** | Package manager | Comes with Node.js |
| **Zeus CLI** | ZeppOS build/dev/deploy tool | `npm i @nicegoodthings/zeus-cli -g` |
| **Zepp App** | Phone companion (for physical device deploy) | App Store / Play Store |

### Account Setup

1. **Register at [console.zepp.com](https://console.zepp.com)** — Create a developer account.
2. **Create an app** in the developer console — You'll receive an `appId` (e.g., `1105800`). This is required; random IDs like `1000001` will fail to deploy.
3. **Enable Developer Mode** in the Zepp phone app:
   - Go to Profile → Settings → About
   - Tap the version number multiple times until developer mode activates
   - This enables the "Developer" section in the app where you can see device logs, side service logs, and scan QR codes for preview deploys

### Creating a New Project

```bash
zeus create my-app-name
```

Choose the **ZML template** (specifically one with `app-side` like `helloworld3` or `fetch`) to get the BLE communication framework pre-configured.

After creation:

```bash
cd my-app-name
npm install
```

---

## 3. Project Structure

```
WatchApp/TaskIt/
├── app.js                          # App entry point — wraps App() with BaseApp
├── app.json                        # App manifest — config, pages, permissions
├── package.json                    # npm dependencies (@zeppos/zml)
├── jsconfig.json                   # JS compiler config (ES6, CommonJS)
├── global.d.ts                     # TypeScript device API references
├── .gitignore
│
├── assets/                         # Icons for different screen shapes
│   ├── common.r/                   # Round display icons
│   │   └── icon.png
│   ├── common.s/                   # Square display icons
│   │   └── icon.png
│   └── bip6.s/                     # Device-specific icons (optional)
│       └── icon.png
│
├── page/                           # Watch UI pages
│   ├── index.js                    # Main menu page
│   ├── index.r.layout.js           # Menu layout — round display
│   ├── index.s.layout.js           # Menu layout — square display
│   ├── lists.js                    # Lists page
│   ├── lists.r.layout.js           # Lists layout — round
│   ├── lists.s.layout.js           # Lists layout — square
│   ├── tasks.js                    # Tasks page
│   ├── tasks.r.layout.js           # Tasks layout — round
│   ├── tasks.s.layout.js           # Tasks layout — square
│   ├── habits.js                   # Habits page
│   ├── habits.r.layout.js          # Habits layout — round
│   ├── habits.s.layout.js          # Habits layout — square
│   └── i18n/
│       └── en-US.po                # Localization
│
├── app-side/                       # Phone-side service (BLE + HTTP)
│   ├── index.js                    # Side service — API communication layer
│   └── i18n/
│       └── en-US.po
│
├── setting/                        # Companion app settings UI
│   └── index.js                    # Settings page (user ID input)
│
├── utils/
│   └── config/
│       ├── device.js               # Runtime device dimensions
│       └── constants.js            # Colors, API URL, defaults
│
└── dist/                           # Build output
    └── *.zab                       # ZeppOS App Bundle
```

### The Platform-Suffix Convention

ZeppOS uses a file naming convention to load different layouts for different screen shapes:

- `page/index.js` — The page logic (shared across all devices)
- `page/index.r.layout.js` — Layout config for **r**ound displays
- `page/index.s.layout.js` — Layout config for **s**quare displays

The magic import that makes this work:

```js
import { TITLE_TEXT, MENU_AREA } from "zosLoader:./index.[pf].layout.js";
```

`[pf]` is replaced at build time with `r` or `s` based on the target device's screen shape. This is NOT a standard JS import — it's a Zeus/ZeppOS build-time transform.

### Asset Directories

Assets follow a similar convention:

- `assets/common.r/` — Assets for round displays
- `assets/common.s/` — Assets for square displays

The directory name format is `{target-name}.{screen-shape}/`. When using the default "common" target, the directories are `common.r/` and `common.s/`.

**CRITICAL:** The `icon.png` referenced in `app.json` must exist in BOTH `common.r/` and `common.s/` directories. Missing icons cause the build to fail with: `"The icon in app.json is empty or the image does not exist"`.

---

## 4. app.json Configuration (v3 Format)

This is the most error-prone file in the entire project. Here is the working configuration:

```json
{
  "configVersion": "v3",
  "app": {
    "appId": 1105800,
    "appName": "TaskIt",
    "appType": "app",
    "version": {
      "code": 1,
      "name": "1.0.0"
    },
    "icon": "icon.png",
    "vender": "TaskIt",
    "description": "Todo list and habit tracker for your wrist"
  },
  "permissions": [
    "data:os.device.info"
  ],
  "runtime": {
    "apiVersion": {
      "compatible": "3.0",
      "target": "3.0",
      "minVersion": "3.0"
    }
  },
  "debug": true,
  "targets": {
    "common": {
      "module": {
        "page": {
          "pages": [
            "page/index",
            "page/lists",
            "page/tasks",
            "page/habits"
          ]
        },
        "app-side": {
          "path": "app-side/index"
        },
        "setting": {
          "path": "setting/index"
        }
      },
      "platforms": [
        {
          "st": "s"
        }
      ],
      "designWidth": 390
    }
  },
  "i18n": {
    "en-US": {
      "appName": "TaskIt"
    }
  },
  "defaultLanguage": "en-US"
}
```

### Field-by-Field Explanation

| Field | Value | Notes |
|-------|-------|-------|
| `configVersion` | `"v3"` | MUST be v3 for current Zeus CLI. v2 uses a completely different format. |
| `app.appId` | `1105800` | **Must be registered** on console.zepp.com. Random/placeholder IDs will fail on physical device deploy. |
| `app.appType` | `"app"` | Can be `"app"` or `"watchface"`. |
| `app.icon` | `"icon.png"` | Filename only — Zeus looks for it in `assets/{target}.{screenShape}/`. |
| `app.vender` | `"TaskIt"` | Note the typo: it's `vender`, not `vendor`. This is ZeppOS's field name. |
| `permissions` | `["data:os.device.info"]` | Required to use `getDeviceInfo()` for screen dimensions. |
| `runtime.apiVersion` | `"3.0"` | ZeppOS API level. Use 3.0 for modern devices. |
| `debug` | `true` | Enables debug logging. Set to `false` for production. |
| `targets.common` | Object | The target name becomes the asset directory prefix (e.g., `assets/common.s/`). |
| `module.page.pages` | Array | List of page paths WITHOUT file extensions. |
| `module.app-side.path` | String | Path to side service entry WITHOUT extension. |
| `module.setting.path` | String | Path to settings page entry WITHOUT extension. |
| `platforms` | `[{ "st": "s" }]` | **See critical warning below.** |
| `designWidth` | `390` | The reference width for `px()` calculations. Match your target device. |

### CRITICAL: The `platforms` Array

In v3 configVersion, the `platforms` array specifies supported screen shapes:

```json
"platforms": [
  { "st": "s" }
]
```

- `"st": "s"` — square screen type
- `"st": "r"` — round screen type
- Include both if you support both: `[{ "st": "s" }, { "st": "r" }]`

**DO NOT add `deviceSource` or `name` fields to platforms in v3.** Every attempt to add these causes the build to fail with: `"The icon in app.json is empty or the image does not exist"`.

```json
// BAD — WILL FAIL:
"platforms": [{ "st": "s", "deviceSource": 9765120 }]
"platforms": [{ "st": "s", "name": "bip6", "deviceSource": 9765120 }]
"platforms": [{ "st": "s", "name": "common" }]

// GOOD — WORKS:
"platforms": [{ "st": "s" }]
```

**Why?** In v3, Zeus CLI handles device source mapping INTERNALLY when you run `zeus dev` (simulator) or `zeus preview` (physical device). It prompts you to select a device and auto-injects the correct device sources into the build. You don't need to (and must not) hardcode them.

**The v2 alternative:** If you absolutely need `deviceSource` in the config (e.g., for specific device targeting), you'd need to use `"configVersion": "v2"` which has a completely different JSON structure. This is rarely needed.

---

## 5. ZML Framework Deep Dive

ZML (`@zeppos/zml`) is a meta-language framework for ZeppOS that provides the communication layer between the watch, phone side service, and settings page. It is NOT the same as the raw ZeppOS API.

### Installation

```json
{
  "dependencies": {
    "@zeppos/zml": "^0.0.38"
  }
}
```

### The Four Base Classes

#### 1. `BaseApp` — App Entry Point

```js
import { BaseApp } from "@zeppos/zml/base-app";

App(
  BaseApp({
    globalData: {},
    onCreate(options) { },
    onDestroy(options) { },
  })
);
```

Wraps the ZeppOS `App()` call. Required for ZML's communication system to initialize.

#### 2. `BasePage` — Watch Pages

```js
import { BasePage } from "@zeppos/zml/base-page";

Page(
  BasePage({
    state: { /* reactive state */ },

    build() {
      // Create UI widgets here
    },

    onInit(params) {
      // Called before build, receives route params as JSON string
    },

    // Custom methods
    async fetchData() {
      const response = await this.request({
        method: "METHOD_NAME",
        params: { key: "value" }
      });
      // response = { result: ..., error: ... }
    },
  })
);
```

**Key methods provided by BasePage:**
- `this.request({ method, params })` — Sends a message to the phone side service over BLE. Returns a Promise that resolves with the side service's response.
- `this.state` — A state object for storing page data. Works within BasePage (but NOT in AppSettingsPage — see gotchas).

#### 3. `BaseSideService` — Phone Side Service

```js
import { BaseSideService } from "@zeppos/zml/base-side";
import { settingsLib } from "@zeppos/zml/base-side";

AppSideService(
  BaseSideService({
    onInit() {
      this.log("Side service started");
    },

    onRequest(req, res) {
      // req = { method: "METHOD_NAME", params: { ... } }
      // res = function(error, data) — call to send response back to watch

      switch (req.method) {
        case "GET_DATA":
          this.fetch({ url: "https://api.example.com/data", method: "GET" })
            .then(response => {
              const body = typeof response.body === "string"
                ? JSON.parse(response.body)
                : response.body;
              res(null, { result: body.data });
            })
            .catch(e => {
              res(null, { result: [], error: String(e) });
            });
          break;
      }
    },

    onRun() { },
    onDestroy() { },
  })
);
```

**Key methods provided by BaseSideService:**
- `this.fetch(options)` — Makes HTTP requests FROM THE PHONE to the internet. This is how the watch accesses APIs. Options: `{ url, method, headers, body }`.
- `this.log(...)` — Logs to the Zepp developer mode "Side Service" log panel. **CRITICAL: This is the ONLY way to see logs from the side service.** `console.log()` is completely invisible.
- `this.onRequest(req, res)` — Handler for incoming requests from the watch. Called via ZML's jsonrpc protocol over BLE.
- `settingsLib.getItem(key)` / `settingsLib.setItem(key, value)` — Persistent key-value storage (strings only).

#### 4. `AppSettingsPage` — Companion App Settings

```js
AppSettingsPage({
  build(props) {
    // props.settingsStorage.getItem(key) / setItem(key, value)
    let myValue = props.settingsStorage.getItem("myKey") || "";

    return Section({}, [
      Text({}, ["Title"]),
      TextInput({
        label: "Label",
        value: myValue,
        onChange: (val) => { myValue = val; },
      }),
      Button({
        label: "Save",
        onClick: () => {
          props.settingsStorage.setItem("myKey", myValue);
        },
      }),
    ]);
  },
});
```

**CRITICAL:** `this.state` does NOT work inside `AppSettingsPage.build()`. Use closure variables (`let myValue = ...`) to track input state, and save to `settingsStorage` on button click.

### settingsLib vs settingsStorage

These are TWO DIFFERENT storage APIs that access THE SAME underlying storage:

- **`settingsLib`** — Available in the side service (`import { settingsLib } from "@zeppos/zml/base-side"`). Uses `settingsLib.getItem(key)` / `settingsLib.setItem(key, value)`.
- **`props.settingsStorage`** — Available in the settings page via the `build(props)` argument. Uses `props.settingsStorage.getItem(key)` / `props.settingsStorage.setItem(key, value)`.

Both read/write the same data. When the settings page saves a value, the side service can immediately read it (and vice versa). The side service also receives an `onSettingsChange({ key, newValue, oldValue })` callback when settings change.

**Important:** Both store plain strings. There is no automatic JSON encoding. If you store `settingsLib.setItem("config", JSON.stringify(obj))`, you must `JSON.parse(settingsLib.getItem("config"))` to read it back.

---

## 6. BLE Communication Architecture

### The "Shake" Handshake

Before the watch and phone can communicate, they perform a BLE handshake called a "shake":

- **"shake success"** — BLE connection established. Requests from the watch will reach the side service.
- **"shake timeout"** — BLE connection failed. All `this.request()` calls from the watch will fail.

**Common causes of "shake timeout":**
- Running in the simulator without the side service panel connected (port 7833)
- Phone Zepp app not running
- BLE disconnected between watch and phone
- App not installed/registered properly

**When testing:** The simulator frequently fails to connect the side service. Always test API calls on a physical device where "shake success" is confirmed.

### Request Flow

```
1. Watch page calls:        this.request({ method: "GET_LISTS" })
2. ZML encodes as jsonrpc:  { jsonrpc: "2.0", method: "GET_LISTS", id: 1 }
3. Sent over BLE to phone
4. Side service receives:   onRequest(req, res) where req.method = "GET_LISTS"
5. Side service calls:      this.fetch({ url: "https://api.example.com/..." })
6. HTTP request goes to API server via phone's internet
7. API response received
8. Side service calls:      res(null, { result: data })
9. Response sent back over BLE to watch
10. Promise resolves:       .then(data => { /* data.result contains the API data */ })
```

### The `res()` Callback Pattern

In `onRequest(req, res)`, the `res` function sends data back to the watch:

```js
// Success response:
res(null, { result: someData });

// Error response (still null first arg — always null):
res(null, { result: null, error: "Something went wrong" });
```

The first argument is always `null`. The second argument is the response object. On the watch side, the Promise resolves with this response object, so `data.result` gives you the actual data.

---

## 7. Connecting to a REST API

### The fetchDirectus Helper Pattern

This reusable pattern handles all HTTP communication with a REST API:

```js
async fetchDirectus(path, method, body) {
  method = method || "GET";
  const options = {
    url: BASE_URL + path,
    method: method,
    headers: {
      "Content-Type": "application/json",
    },
  };

  if (body) {
    options.body = JSON.stringify(body);
  }

  this.log("fetchDirectus:", method, options.url);

  try {
    const response = await this.fetch(options);

    // IMPORTANT: response.body can be a string OR an already-parsed object
    // depending on the Content-Type header of the response
    const resBody =
      typeof response.body === "string"
        ? JSON.parse(response.body)
        : response.body;

    return resBody;
  } catch (e) {
    this.log("fetchDirectus FETCH ERROR:", e.message || String(e));
    throw e;
  }
},
```

### Key Points About `this.fetch()`

1. **`options.body` must be a string** — Always `JSON.stringify()` the body before passing it.
2. **`response.body` can be string OR object** — ZML may auto-parse JSON responses. Always check `typeof response.body` before parsing.
3. **`response.status`** — The HTTP status code (200, 404, etc.).
4. **No authentication headers needed** if your API has public read/write access (like our Directus setup).

### Directus Filter Syntax

Directus uses a bracket-based filter syntax in query strings:

```
/items/todos?filter[user_id][_eq]=013003          # user_id equals "013003"
/items/todos?filter[list_id][_eq]=5               # list_id equals 5
/items/todos?filter[user_id][_eq]=1&sort=title    # with sorting
```

**Common operators:**
- `_eq` — equals
- `_neq` — not equals
- `_gt` / `_gte` — greater than / greater or equal
- `_lt` / `_lte` — less than / less or equal
- `_contains` — string contains
- `_in` — value in array

### CRUD Operations

```js
// READ — Get all items with filter
this.fetchDirectus("/items/lists?filter[user_id][_eq]=" + userId)

// CREATE — Post new item
this.fetchDirectus("/items/todos", "POST", {
  title: "New task",
  is_completed: false,
  user_id: userId,
})

// UPDATE — Patch existing item
this.fetchDirectus("/items/todos/" + itemId, "PATCH", {
  is_completed: true,
})

// DELETE — Remove item
this.fetchDirectus("/items/todos/" + itemId, "DELETE")
```

### User Scoping

Every query MUST include a user filter to ensure data isolation:

```js
getUserId() {
  try {
    const stored = settingsLib.getItem("userId");
    if (stored) return String(stored).trim();  // ALWAYS return as string
  } catch (e) {
    this.log("getUserId fallback to default:", e);
  }
  return DEFAULT_USER_ID;  // DEFAULT_USER_ID = "1" (string, not integer)
},
```

**CRITICAL:** Always return user IDs as STRINGS, never use `parseInt()`. See [Bug #1 in Gotchas](#10-bugs--gotchas-lessons-learned).

---

## 8. Settings Page (Companion App)

The settings page renders in the Zepp phone app when the user navigates to the app's settings. It uses a React-like component syntax (but it's NOT React).

### Working Settings Page

```js
AppSettingsPage({
  build(props) {
    // Use a closure variable — NOT this.state (see gotchas)
    let userId = props.settingsStorage.getItem("userId") || "";

    return Section({}, [
      // Title
      View({ style: { marginTop: "30px", textAlign: "center" } }, [
        Text(
          { style: { fontSize: "24px", fontWeight: "bold", color: "#BB86FC" } },
          ["TaskIt Settings"]
        ),
      ]),

      // Input field
      View({ style: { marginTop: "30px", padding: "0 20px" } }, [
        Text(
          { style: { fontSize: "16px", color: "#999999", marginBottom: "10px" } },
          ["User ID"]
        ),
        TextInput({
          label: "User ID",
          placeholder: "Enter your user ID",
          value: userId,
          subStyle: { fontSize: "18px" },
          onChange: (val) => { userId = val; },  // Updates closure variable
        }),
      ]),

      // Save button
      View({ style: { marginTop: "20px", textAlign: "center" } }, [
        Button({
          label: "Save",
          color: "primary",
          onClick: () => {
            if (userId) {
              props.settingsStorage.setItem("userId", userId);
            }
          },
        }),
      ]),

      // Status display
      View({ style: { marginTop: "30px", padding: "0 20px" } }, [
        Text(
          { style: { fontSize: "14px", color: "#666666" } },
          [userId ? "Current User ID: " + userId : "No user ID set (using default: 1)"]
        ),
      ]),
    ]);
  },
});
```

### Available Components

- `Section({}, children)` — Container section
- `View({ style }, children)` — Generic container (like a div)
- `Text({ style }, [text])` — Text display (note: text is in an array)
- `TextInput({ label, placeholder, value, onChange })` — Text input field
- `Button({ label, color, onClick })` — Clickable button
- `Toggle({ label, value, onChange })` — Toggle switch

### Settings ↔ Side Service Sync

When the settings page writes via `props.settingsStorage.setItem()`, the side service's `onSettingsChange()` is called:

```js
// In side service:
onSettingsChange({ key, newValue, oldValue }) {
  this.log("Settings changed:", key, newValue);
  if (key === "userId" && newValue) {
    this.log("User ID updated from settings:", newValue);
  }
},
```

The side service reads the same storage with `settingsLib.getItem("userId")`.

---

## 9. Watch UI Patterns

### Widget Lifecycle

ZeppOS uses imperative widget creation — there's no virtual DOM or declarative rendering:

```js
// Create a widget
const widget = hmUI.createWidget(hmUI.widget.TEXT, {
  x: 0, y: 0, w: 390, h: 50,
  text: "Hello",
  color: 0xffffff,
  text_size: px(28),
  align_h: hmUI.align.CENTER_H,
});

// Update a widget (limited — some props can't be updated)
widget.setProperty(hmUI.prop.TEXT, "Updated text");

// Delete a widget
hmUI.deleteWidget(widget);
```

**Pattern for dynamic lists:** Delete the old `SCROLL_LIST` widget and create a new one with updated data. There's no way to update items in-place.

```js
if (this.state.scrollList) {
  hmUI.deleteWidget(this.state.scrollList);
  this.state.scrollList = null;
}
this.state.scrollList = hmUI.createWidget(hmUI.widget.SCROLL_LIST, { ... });
```

### SCROLL_LIST Widget

This is the most complex widget. Here's the full pattern:

```js
hmUI.createWidget(hmUI.widget.SCROLL_LIST, {
  // Position and size
  x: px(10),
  y: px(70),
  w: DEVICE_WIDTH - px(20),
  h: DEVICE_HEIGHT - px(160),

  // Spacing between items
  item_space: px(6),
  snap_to_center: true,

  // Item templates (array of configs, one per type_id)
  item_config: [
    {
      type_id: 1,                        // Template identifier
      item_bg_color: 0x1e1e2e,           // Background color
      item_bg_radius: px(12),            // Corner radius
      item_height: px(60),               // Item height
      text_view: [                       // Text elements within the item
        {
          x: px(16),
          y: px(0),
          w: DEVICE_WIDTH - px(60),
          h: px(60),
          key: "name",                   // Maps to data_array[i].name
          color: 0xffffff,
          text_size: px(26),
          action: true,                  // Makes the text area clickable
        },
      ],
      text_view_count: 1,
      image_view: [],
      image_view_count: 0,
    },
    // Can have multiple templates for different item types (e.g., completed vs incomplete)
  ],
  item_config_count: 1,                  // Number of templates

  // Data
  data_array: [
    { name: "Item 1" },
    { name: "Item 2" },
  ],
  data_count: 2,

  // Map data indices to template type_ids
  data_type_config: [
    { start: 0, end: 2, type_id: 1 },   // Items 0-1 use template type_id 1
  ],
  data_type_config_count: 1,

  // Click handler
  item_click_func: (item, index) => {
    console.log("Clicked item at index:", index);
  },
});
```

### Multiple Item Types (e.g., Completed vs Incomplete Tasks)

```js
// Define two templates
item_config: [TASK_ITEM_CONFIG, TASK_DONE_ITEM_CONFIG],  // type_id: 1 and type_id: 2
item_config_count: 2,

// Map each item to its template based on completion status
data_type_config: todos.map((todo, i) => ({
  start: i,
  end: i + 1,
  type_id: todo.is_completed ? 2 : 1,  // Use different template per item
})),
data_type_config_count: todos.length,
```

### Two-Line Items (e.g., Habits with Progress)

```js
{
  type_id: 1,
  item_bg_color: COLOR_BG_CARD,
  item_bg_radius: px(12),
  item_height: px(76),               // Taller to fit two lines
  text_view: [
    {
      x: px(14), y: px(6),
      w: DEVICE_WIDTH - px(50), h: px(36),
      key: "name",                    // First line: habit name
      color: COLOR_TEXT,
      text_size: px(24),
      action: true,
    },
    {
      x: px(14), y: px(40),
      w: DEVICE_WIDTH - px(50), h: px(30),
      key: "progress",               // Second line: progress text
      color: COLOR_HABIT,             // Different color for progress
      text_size: px(20),
    },
  ],
  text_view_count: 2,                 // Two text views
  image_view: [],
  image_view_count: 0,
},
```

### Keyboard Input

```js
import { createKeyboard, inputType, deleteKeyboard } from "@zos/ui";

createKeyboard({
  inputType: inputType.NORMAL,
  onComplete: (_, result) => {
    const text = result.data;         // The entered text
    if (text && text.trim()) {
      // Do something with the text
    }
    deleteKeyboard();                 // Must call to dismiss
  },
  onCancel: () => {
    deleteKeyboard();                 // Must call to dismiss
  },
  text: "",                           // Initial text (empty)
});
```

### Navigation

```js
import { push } from "@zos/router";

// Navigate to a page
push({ url: "page/tasks" });

// Navigate with parameters
push({
  url: "page/tasks",
  params: {
    listId: 5,
    title: "My List",
  },
});
```

**CRITICAL:** `params` is an OBJECT. Do NOT pre-stringify it with `JSON.stringify()`. ZeppOS auto-serializes params objects. If you double-stringify, the receiving page gets a double-encoded string.

On the receiving page, params arrive as a JSON string in `onInit`:

```js
onInit(params) {
  if (params) {
    try {
      const parsed = JSON.parse(params);
      this.state.listId = parsed.listId;
      this.state.title = parsed.title;
    } catch (e) {
      // Handle parse error
    }
  }
},
```

### Layout Pattern — Round vs Square

Each page has two layout files exporting the same constants but with different sizing:

**Round (`.r.layout.js`):**
- Larger text sizes (34-38px titles, 26-30px body)
- More padding/margin (20-30px)
- Larger items (64-90px height)
- More spacing between items (8-10px)
- Positioned further from edges (round displays clip corners)

**Square (`.s.layout.js`):**
- Smaller text sizes (30-34px titles, 24-26px body)
- Less padding (10-20px)
- Smaller items (56-76px height)
- Tighter spacing (5-6px)
- Can use full screen width (no corner clipping)

### The `px()` Function

```js
import { px } from "@zos/utils";
```

Converts design pixels to actual device pixels based on the `designWidth` in `app.json`. If `designWidth` is 390 and the actual device width is 390, `px(100)` = 100. On a device with a different width, it scales proportionally.

### Dynamic Device Dimensions

```js
import { getDeviceInfo } from "@zos/device";
export const { width: DEVICE_WIDTH, height: DEVICE_HEIGHT } = getDeviceInfo();
```

Use these for responsive positioning (e.g., centering a button: `x: (DEVICE_WIDTH - btnSize) / 2`).

---

## 10. Bugs & Gotchas (Lessons Learned)

These are real bugs encountered during development. Each one took significant time to diagnose. Future AI agents: READ ALL OF THESE before writing any ZeppOS code.

### Bug #1: `parseInt()` Strips Leading Zeros from User IDs

**Problem:** User ID `"013003"` stored in Directus as a string. Side service called `parseInt("013003")` which returned `13003`. The API filter `filter[user_id][_eq]=13003` didn't match `"013003"` in the database. Result: empty data.

**Verified with curl:**
```bash
# Returns data:
curl "https://api.example.com/items/lists?filter[user_id][_eq]=013003"

# Returns {"data":[]} — empty:
curl "https://api.example.com/items/lists?filter[user_id][_eq]=13003"
```

**Fix:** NEVER use `parseInt()` on IDs. Always use `String(stored).trim()`:

```js
// BAD:
const DEFAULT_USER_ID = 1;
getUserId() {
  const stored = settingsLib.getItem("userId");
  if (stored) return parseInt(stored);  // Strips leading zeros!
  return DEFAULT_USER_ID;
}

// GOOD:
const DEFAULT_USER_ID = "1";
getUserId() {
  const stored = settingsLib.getItem("userId");
  if (stored) return String(stored).trim();
  return DEFAULT_USER_ID;
}
```

### Bug #2: `console.log()` is Invisible in Zepp Developer Mode

**Problem:** All `console.log()` calls in the side service produce no visible output anywhere. The side service appeared to be silent — no way to debug.

**Fix:** Use `this.log()` which is provided by `BaseSideService`. This outputs to the "Side Service" log panel in the Zepp phone app's developer mode.

```js
// BAD — invisible:
console.log("Debug info:", data);

// GOOD — visible in Zepp developer mode:
this.log("Debug info:", data);
```

**Note:** `console.log()` DOES work on the watch side (device pages) and appears in "Device Logs". It's only the side service where `console.log()` is invisible. However, for consistency, prefer using loggers everywhere:

```js
// Watch pages — use Logger:
import { log as Logger } from "@zos/utils";
const logger = Logger.getLogger("my_page");
logger.log("Message");
```

### Bug #3: `this.state` Doesn't Work in `AppSettingsPage.build()`

**Problem:** Trying to use `this.state` to track input values in the settings page fails silently. The input appears to work but the value is never actually updated.

**Fix:** Use closure variables:

```js
// BAD — silently fails:
AppSettingsPage({
  state: { userId: "" },
  build(props) {
    return TextInput({
      value: this.state.userId,            // undefined or stale
      onChange: (val) => { this.state.userId = val; },  // Doesn't persist
    });
  },
});

// GOOD — works:
AppSettingsPage({
  build(props) {
    let userId = props.settingsStorage.getItem("userId") || "";
    return TextInput({
      value: userId,
      onChange: (val) => { userId = val; },  // Updates closure variable
    });
  },
});
```

### Bug #4: v3 configVersion + `deviceSource` in Platforms = Build Failure

**Problem:** Adding `deviceSource` (or `name`) to the `platforms` array in `app.json` v3 format causes: `"The icon in app.json is empty or the image does not exist"`.

**Root cause:** v3 config format resolves asset directories differently than v2. When `name` is added to a platform entry, the build looks for `assets/{name}.{st}/` (e.g., `assets/bip6.s/`) instead of `assets/{target}.{st}/` (e.g., `assets/common.s/`). Even creating the expected directory doesn't always fix it.

**Fix:** Use bare `{ "st": "s" }` and let `zeus dev` / `zeus preview` handle device targeting.

### Bug #5: `push()` Params Double-Encoding

**Problem:** If you pass `params: JSON.stringify({ listId: 5 })` to `push()`, the receiving page gets a double-encoded string because ZeppOS auto-serializes the params.

```js
// BAD — double encoding:
push({ url: "page/tasks", params: JSON.stringify({ listId: 5 }) });
// Receiver gets: '"{\\"listId\\":5}"' — a stringified string

// GOOD — pass object directly:
push({ url: "page/tasks", params: { listId: 5, title: "My List" } });
// Receiver gets: '{"listId":5,"title":"My List"}' — clean JSON
```

### Bug #6: settingsStorage Stores Only Strings

**Problem:** `settingsStorage.setItem("config", { key: "value" })` silently converts the object to `"[object Object]"`.

**Fix:** Always stringify before storing, parse after reading:

```js
// Store:
settingsStorage.setItem("config", JSON.stringify({ key: "value" }));

// Read:
const config = JSON.parse(settingsStorage.getItem("config") || "{}");
```

### Bug #7: Simulator Cannot Connect Side Service BLE

**Problem:** In the simulator, the watch-to-phone BLE connection (the "shake") almost always times out. The side service log panel (port 7833) doesn't connect.

**Impact:** Any `this.request()` call from a watch page fails in the simulator. You see "shake timeout" in device logs.

**Fix:** Test API functionality on a physical watch. The simulator is only useful for testing UI layout.

### Bug #8: appId Must Be Registered

**Problem:** Using a random `appId` like `1000001` allows building and running in the simulator, but deploying to a physical device via `zeus preview` fails with "send package to device failed".

**Fix:** Register your app at [console.zepp.com](https://console.zepp.com) and use the assigned appId.

### Bug #9: `this.fetch()` Response Body Type Varies

**Problem:** Sometimes `response.body` is a pre-parsed JavaScript object, sometimes it's a JSON string. This depends on the response's Content-Type header and ZML's internal parsing logic.

**Fix:** Always check the type:

```js
const resBody =
  typeof response.body === "string"
    ? JSON.parse(response.body)
    : response.body;
```

---

## 11. Build, Deploy & Debug

### Build Commands

| Command | Purpose | Notes |
|---------|---------|-------|
| `zeus build` | Build the `.zab` package | Output in `dist/` directory |
| `zeus dev` | Build + deploy to simulator | Auto-adds device sources; asks which device to emulate |
| `zeus preview` | Build + generate QR code for physical device | Scan QR in Zepp app → installs on watch |

### Build Process

```bash
cd WatchApp/TaskIt
zeus build
```

Output:
```
[ROLLUP] Transform JS files
[RESIZE] Resize icon.png to target sizes
[PNG2TGA] Convert PNGs to TGA format
[QJSC] Compile JS files (QuickJS bytecode)
```

The built package is at: `dist/{appId}-{appName}-{version}-{timestamp}.zab`

### Simulator Deployment

```bash
zeus dev
```

1. Zeus prompts you to select a target device (e.g., "Amazfit Bip 6")
2. It auto-injects the correct `deviceSource` values
3. Builds and deploys to the ZeppOS simulator
4. Simulator runs on port 7650 (device) and 7833 (side service)
5. **Remember:** BLE/side service usually doesn't work in simulator

### Physical Device Deployment

```bash
zeus preview
```

1. Builds the app
2. Generates a QR code in the terminal
3. Open Zepp phone app → Developer section → Scan QR code
4. App installs on your connected watch
5. **Requires:** Developer mode enabled, watch paired, Zepp app running

### Debugging

**Device Logs (Watch):**
- Open Zepp phone app → Developer → Device Logs
- Shows output from `Logger.getLogger("name").log(...)` and `console.log()` on watch pages
- Prefixed with `[AppName]` tag
- Shows BLE shake status: "shake success" or "shake timeout"

**Side Service Logs (Phone):**
- Open Zepp phone app → Developer → (look for side service section)
- Shows output from `this.log(...)` in BaseSideService
- `console.log()` does NOT appear here — only `this.log()`
- Shows API request/response details if you've added logging

**Common Log Messages:**
```
[TaskIt] [timestamp] shake success          → BLE connected, ready for requests
[TaskIt] [timestamp] shake timeout          → BLE failed, requests will error
[TaskIt] fetchDirectus: GET https://...     → API call being made
[TaskIt] fetchDirectus response status: 200 → API response received
[TaskIt] Side service request: GET_LISTS userId: 013003  → Request with user context
```

---

## 12. Complete Code Reference

Below is the complete source of every file in the working app, with inline annotations explaining key decisions.

### app.js

```js
import { BaseApp } from "@zeppos/zml/base-app";

App(
  BaseApp({
    globalData: {},
    onCreate(options) {
      console.log("TaskIt app created");
    },
    onDestroy(options) {
      console.log("TaskIt app destroyed");
    },
  })
);
```

### app-side/index.js — The Side Service (Most Important File)

```js
import { BaseSideService } from "@zeppos/zml/base-side";
import { settingsLib } from "@zeppos/zml/base-side";

// API base URL — no trailing slash
const BASE_URL = "https://api.opcw032522.uk";

// MUST be a string, not integer — parseInt would strip leading zeros
const DEFAULT_USER_ID = "1";

AppSideService(
  BaseSideService({
    onInit() {
      // Use this.log(), NOT console.log() — console.log is invisible in Zepp dev mode
      this.log("TaskIt side service initialized");
    },

    getUserId() {
      try {
        const stored = settingsLib.getItem("userId");
        // CRITICAL: Return as String, never parseInt
        // parseInt("013003") = 13003 which won't match "013003" in the database
        if (stored) return String(stored).trim();
      } catch (e) {
        this.log("getUserId fallback to default:", e);
      }
      return DEFAULT_USER_ID;
    },

    async fetchDirectus(path, method, body) {
      method = method || "GET";
      const options = {
        url: BASE_URL + path,
        method: method,
        headers: {
          "Content-Type": "application/json",
        },
      };

      // body must be a string for this.fetch()
      if (body) {
        options.body = JSON.stringify(body);
      }

      this.log("fetchDirectus:", method, options.url);

      try {
        const response = await this.fetch(options);
        this.log("fetchDirectus response status:", response.status);

        // response.body can be string OR already-parsed object
        const resBody =
          typeof response.body === "string"
            ? JSON.parse(response.body)
            : response.body;

        return resBody;
      } catch (e) {
        this.log("fetchDirectus FETCH ERROR:", e.message || String(e));
        throw e;
      }
    },

    onSettingsChange({ key, newValue, oldValue }) {
      this.log("Settings changed:", key, newValue);
    },

    onRequest(req, res) {
      const userId = this.getUserId();
      this.log("Side service request:", req.method, "userId:", userId);

      switch (req.method) {
        // ═══════════════════════════════════════
        // READ OPERATIONS
        // ═══════════════════════════════════════

        case "GET_LISTS":
          this.fetchDirectus(
            "/items/lists?filter[user_id][_eq]=" + userId
          )
            .then((data) => res(null, { result: data.data || [] }))
            .catch((e) => {
              this.log("GET_LISTS error:", e);
              res(null, { result: [], error: String(e) });
            });
          break;

        case "GET_TODOS": {
          let path = "/items/todos?filter[user_id][_eq]=" + userId;
          if (req.params && req.params.listId) {
            path += "&filter[list_id][_eq]=" + req.params.listId;
          }
          path += "&sort=is_completed,title";
          this.fetchDirectus(path)
            .then((data) => res(null, { result: data.data || [] }))
            .catch((e) => {
              this.log("GET_TODOS error:", e);
              res(null, { result: [], error: String(e) });
            });
          break;
        }

        case "GET_HABITS":
          this.fetchDirectus(
            "/items/habits?filter[user_id][_eq]=" + userId
          )
            .then((data) => res(null, { result: data.data || [] }))
            .catch((e) => {
              this.log("GET_HABITS error:", e);
              res(null, { result: [], error: String(e) });
            });
          break;

        // ═══════════════════════════════════════
        // CREATE OPERATIONS
        // ═══════════════════════════════════════

        case "CREATE_LIST":
          this.fetchDirectus("/items/lists", "POST", {
            title: req.params.title,
            color: req.params.color || "#BB86FC",
            user_id: userId,
          })
            .then((data) => res(null, { result: data.data }))
            .catch((e) => {
              this.log("CREATE_LIST error:", e);
              res(null, { result: null, error: String(e) });
            });
          break;

        case "CREATE_TODO":
          this.fetchDirectus("/items/todos", "POST", {
            title: req.params.title,
            is_completed: false,
            list_id: req.params.listId || null,
            priority: req.params.priority || "none",
            user_id: userId,
          })
            .then((data) => res(null, { result: data.data }))
            .catch((e) => {
              this.log("CREATE_TODO error:", e);
              res(null, { result: null, error: String(e) });
            });
          break;

        case "CREATE_HABIT":
          this.fetchDirectus("/items/habits", "POST", {
            title: req.params.title,
            target_count: req.params.targetCount || 1,
            current_progress: 0,
            frequency: req.params.frequency || "daily",
            repeat_interval: 1,
            goal_type: "daily",
            current_streak: 0,
            best_streak: 0,
            icon: req.params.icon || "⭐",
            color: req.params.color || "#FFAB40",
            user_id: userId,
          })
            .then((data) => res(null, { result: data.data }))
            .catch((e) => {
              this.log("CREATE_HABIT error:", e);
              res(null, { result: null, error: String(e) });
            });
          break;

        // ═══════════════════════════════════════
        // UPDATE OPERATIONS
        // ═══════════════════════════════════════

        case "TOGGLE_TODO":
          this.fetchDirectus(
            "/items/todos/" + req.params.id,
            "PATCH",
            { is_completed: req.params.isCompleted }
          )
            .then((data) => res(null, { result: data.data }))
            .catch((e) => {
              this.log("TOGGLE_TODO error:", e);
              res(null, { result: null, error: String(e) });
            });
          break;

        // ═══════════════════════════════════════
        // DELETE OPERATIONS
        // ═══════════════════════════════════════

        case "DELETE_TODO":
          this.fetchDirectus("/items/todos/" + req.params.id, "DELETE")
            .then(() => res(null, { result: true }))
            .catch((e) => {
              this.log("DELETE_TODO error:", e);
              res(null, { result: false, error: String(e) });
            });
          break;

        case "DELETE_LIST":
          this.fetchDirectus("/items/lists/" + req.params.id, "DELETE")
            .then(() => res(null, { result: true }))
            .catch((e) => {
              this.log("DELETE_LIST error:", e);
              res(null, { result: false, error: String(e) });
            });
          break;

        case "DELETE_HABIT":
          this.fetchDirectus("/items/habits/" + req.params.id, "DELETE")
            .then(() => res(null, { result: true }))
            .catch((e) => {
              this.log("DELETE_HABIT error:", e);
              res(null, { result: false, error: String(e) });
            });
          break;

        // ═══════════════════════════════════════
        // COMPLEX OPERATIONS
        // ═══════════════════════════════════════

        case "LOG_HABIT":
          this.handleLogHabit(req, res, userId);
          break;

        case "SET_USER_ID":
          try {
            settingsLib.setItem("userId", String(req.params.userId));
            this.log("User ID set to:", req.params.userId);
            res(null, { result: true });
          } catch (e) {
            this.log("SET_USER_ID error:", e);
            res(null, { result: false, error: String(e) });
          }
          break;

        case "GET_USER_ID":
          res(null, { result: userId });
          break;

        default:
          res(null, { result: null, error: "Unknown method" });
      }
    },

    handleLogHabit(req, res, userId) {
      // 1. Fetch current habit state
      this.fetchDirectus("/items/habits/" + req.params.id)
        .then((habitRes) => {
          const habit = habitRes.data;
          const newProgress = (habit.current_progress || 0) + 1;
          const isNowComplete = newProgress >= (habit.target_count || 1);

          const updateData = { current_progress: newProgress };

          if (isNowComplete) {
            updateData.current_streak = (habit.current_streak || 0) + 1;
            updateData.best_streak = Math.max(
              habit.best_streak || 0,
              (habit.current_streak || 0) + 1
            );
            updateData.last_completed = new Date().toISOString();
          }

          // 2. Update habit with new progress
          return this.fetchDirectus(
            "/items/habits/" + req.params.id,
            "PATCH",
            updateData
          );
        })
        .then((updated) => {
          // 3. Create a habit log entry (fire-and-forget)
          this.fetchDirectus("/items/habit_logs", "POST", {
            habit_id: req.params.id,
            date: new Date().toISOString().split("T")[0],
            completed_count: 1,
          });
          res(null, { result: updated.data });
        })
        .catch((e) => {
          this.log("LOG_HABIT error:", e);
          res(null, { result: null, error: String(e) });
        });
    },

    onRun() {},
    onDestroy() {},
  })
);
```

### setting/index.js — Settings Page

```js
AppSettingsPage({
  build(props) {
    // CRITICAL: Use closure variable, NOT this.state
    let userId = props.settingsStorage.getItem("userId") || "";

    return Section({}, [
      View({ style: { marginTop: "30px", textAlign: "center" } }, [
        Text(
          { style: { fontSize: "24px", fontWeight: "bold", color: "#BB86FC" } },
          ["TaskIt Settings"]
        ),
      ]),
      View({ style: { marginTop: "30px", padding: "0 20px" } }, [
        Text(
          { style: { fontSize: "16px", color: "#999999", marginBottom: "10px" } },
          ["User ID"]
        ),
        TextInput({
          label: "User ID",
          placeholder: "Enter your user ID",
          value: userId,
          subStyle: { fontSize: "18px" },
          onChange: (val) => { userId = val; },
        }),
      ]),
      View({ style: { marginTop: "20px", textAlign: "center" } }, [
        Button({
          label: "Save",
          color: "primary",
          onClick: () => {
            if (userId) {
              props.settingsStorage.setItem("userId", userId);
            }
          },
        }),
      ]),
      View({ style: { marginTop: "30px", padding: "0 20px" } }, [
        Text(
          { style: { fontSize: "14px", color: "#666666" } },
          [userId ? "Current User ID: " + userId : "No user ID set (using default: 1)"]
        ),
      ]),
    ]);
  },
});
```

### page/index.js — Main Menu Page

```js
import * as hmUI from "@zos/ui";
import { push } from "@zos/router";
import { log as Logger } from "@zos/utils";
import { BasePage } from "@zeppos/zml/base-page";
import {
  TITLE_TEXT,
  MENU_AREA,
  MENU_ITEM_CONFIG,
} from "zosLoader:./index.[pf].layout.js";

const logger = Logger.getLogger("index_page");

const MENU_ITEMS = [
  { name: "My Lists", route: "page/lists" },
  { name: "All Tasks", route: "page/tasks" },
  { name: "Habits", route: "page/habits" },
];

Page(
  BasePage({
    state: {},
    build() {
      hmUI.createWidget(hmUI.widget.TEXT, TITLE_TEXT);
      hmUI.createWidget(hmUI.widget.SCROLL_LIST, {
        ...MENU_AREA,
        item_config: [MENU_ITEM_CONFIG],
        item_config_count: 1,
        data_array: MENU_ITEMS.map((item) => ({ name: item.name })),
        data_count: MENU_ITEMS.length,
        data_type_config: [{ start: 0, end: MENU_ITEMS.length, type_id: 1 }],
        data_type_config_count: 1,
        item_click_func: (item, index) => {
          const menuItem = MENU_ITEMS[index];
          if (menuItem) {
            logger.log("Navigate to: " + menuItem.route);
            push({ url: menuItem.route });
          }
        },
      });
    },
  })
);
```

### page/lists.js — Lists Page

```js
import * as hmUI from "@zos/ui";
import { push } from "@zos/router";
import { log as Logger } from "@zos/utils";
import { BasePage } from "@zeppos/zml/base-page";
import { createKeyboard, inputType, deleteKeyboard } from "@zos/ui";
import {
  TITLE_TEXT, LIST_AREA, ADD_BUTTON, LOADING_TEXT, EMPTY_TEXT, ITEM_CONFIG,
} from "zosLoader:./lists.[pf].layout.js";

const logger = Logger.getLogger("lists_page");

Page(
  BasePage({
    state: { lists: [], scrollList: null, loadingWidget: null, emptyWidget: null },

    build() {
      hmUI.createWidget(hmUI.widget.TEXT, TITLE_TEXT);
      this.state.loadingWidget = hmUI.createWidget(hmUI.widget.TEXT, LOADING_TEXT);
      hmUI.createWidget(hmUI.widget.BUTTON, {
        ...ADD_BUTTON,
        click_func: () => this.showKeyboard(),
      });
      this.fetchLists();
    },

    fetchLists() {
      this.request({ method: "GET_LISTS" })
        .then((data) => {
          const lists = data.result || [];
          this.state.lists = lists;

          if (this.state.loadingWidget) {
            hmUI.deleteWidget(this.state.loadingWidget);
            this.state.loadingWidget = null;
          }

          if (lists.length === 0) {
            this.state.emptyWidget = hmUI.createWidget(hmUI.widget.TEXT, EMPTY_TEXT);
            return;
          }
          this.renderLists(lists);
        })
        .catch((e) => logger.log("Error fetching lists: " + e));
    },

    renderLists(lists) {
      if (this.state.emptyWidget) {
        hmUI.deleteWidget(this.state.emptyWidget);
        this.state.emptyWidget = null;
      }
      if (this.state.scrollList) {
        hmUI.deleteWidget(this.state.scrollList);
        this.state.scrollList = null;
      }

      const dataList = lists.map((list) => ({ name: list.title || "Untitled List" }));

      this.state.scrollList = hmUI.createWidget(hmUI.widget.SCROLL_LIST, {
        ...LIST_AREA,
        item_config: [ITEM_CONFIG],
        item_config_count: 1,
        data_array: dataList,
        data_count: dataList.length,
        data_type_config: [{ start: 0, end: dataList.length, type_id: 1 }],
        data_type_config_count: 1,
        item_click_func: (item, index) => {
          const list = this.state.lists[index];
          if (list) {
            // IMPORTANT: params is an object, NOT JSON.stringify'd
            push({ url: "page/tasks", params: { listId: list.id, title: list.title } });
          }
        },
      });
    },

    showKeyboard() {
      createKeyboard({
        inputType: inputType.NORMAL,
        onComplete: (_, result) => {
          const title = result.data;
          if (title && title.trim()) this.createList(title.trim());
          deleteKeyboard();
        },
        onCancel: () => deleteKeyboard(),
        text: "",
      });
    },

    createList(title) {
      this.request({ method: "CREATE_LIST", params: { title } })
        .then(() => this.fetchLists())
        .catch((e) => logger.log("Error creating list: " + e));
    },
  })
);
```

### page/tasks.js — Tasks Page

```js
import * as hmUI from "@zos/ui";
import { log as Logger } from "@zos/utils";
import { BasePage } from "@zeppos/zml/base-page";
import { createKeyboard, inputType, deleteKeyboard } from "@zos/ui";
import {
  TITLE_TEXT, TASK_AREA, ADD_BUTTON, LOADING_TEXT, EMPTY_TEXT,
  TASK_ITEM_CONFIG, TASK_DONE_ITEM_CONFIG,
} from "zosLoader:./tasks.[pf].layout.js";

const logger = Logger.getLogger("tasks_page");

Page(
  BasePage({
    state: {
      todos: [], listId: null, listTitle: null,
      scrollList: null, loadingWidget: null, emptyWidget: null, titleWidget: null,
    },

    onInit(params) {
      // params arrives as a JSON string from push()
      if (params) {
        try {
          const parsed = JSON.parse(params);
          this.state.listId = parsed.listId || null;
          this.state.listTitle = parsed.title || null;
        } catch (e) {
          logger.log("Failed to parse params: " + params);
        }
      }
    },

    build() {
      const titleText = this.state.listTitle || "All Tasks";
      this.state.titleWidget = hmUI.createWidget(hmUI.widget.TEXT, {
        ...TITLE_TEXT,
        text: titleText,
      });
      this.state.loadingWidget = hmUI.createWidget(hmUI.widget.TEXT, LOADING_TEXT);
      hmUI.createWidget(hmUI.widget.BUTTON, {
        ...ADD_BUTTON,
        click_func: () => this.showKeyboard(),
      });
      this.fetchTodos();
    },

    fetchTodos() {
      const reqParams = {};
      if (this.state.listId) reqParams.listId = this.state.listId;

      this.request({ method: "GET_TODOS", params: reqParams })
        .then((data) => {
          const todos = data.result || [];
          this.state.todos = todos;

          if (this.state.loadingWidget) {
            hmUI.deleteWidget(this.state.loadingWidget);
            this.state.loadingWidget = null;
          }

          if (todos.length === 0) {
            this.state.emptyWidget = hmUI.createWidget(hmUI.widget.TEXT, EMPTY_TEXT);
            return;
          }
          this.renderTodos(todos);
        })
        .catch((e) => logger.log("Error fetching todos: " + e));
    },

    renderTodos(todos) {
      if (this.state.emptyWidget) {
        hmUI.deleteWidget(this.state.emptyWidget);
        this.state.emptyWidget = null;
      }
      if (this.state.scrollList) {
        hmUI.deleteWidget(this.state.scrollList);
        this.state.scrollList = null;
      }

      const dataList = todos.map((todo) => ({
        name: todo.is_completed ? "✓ " + todo.title : todo.title,
      }));

      // Each item maps to its own type based on completion status
      const dataTypeConfig = todos.map((todo, i) => ({
        start: i,
        end: i + 1,
        type_id: todo.is_completed ? 2 : 1,
      }));

      this.state.scrollList = hmUI.createWidget(hmUI.widget.SCROLL_LIST, {
        ...TASK_AREA,
        item_config: [TASK_ITEM_CONFIG, TASK_DONE_ITEM_CONFIG],
        item_config_count: 2,
        data_array: dataList,
        data_count: dataList.length,
        data_type_config: dataTypeConfig,
        data_type_config_count: dataTypeConfig.length,
        item_click_func: (item, index) => {
          const todo = this.state.todos[index];
          if (todo) this.toggleTodo(todo);
        },
      });
    },

    toggleTodo(todo) {
      this.request({
        method: "TOGGLE_TODO",
        params: { id: todo.id, isCompleted: !todo.is_completed },
      })
        .then(() => this.fetchTodos())
        .catch((e) => logger.log("Error toggling todo: " + e));
    },

    showKeyboard() {
      createKeyboard({
        inputType: inputType.NORMAL,
        onComplete: (_, result) => {
          const title = result.data;
          if (title && title.trim()) this.createTodo(title.trim());
          deleteKeyboard();
        },
        onCancel: () => deleteKeyboard(),
        text: "",
      });
    },

    createTodo(title) {
      const params = { title };
      if (this.state.listId) params.listId = this.state.listId;
      this.request({ method: "CREATE_TODO", params })
        .then(() => this.fetchTodos())
        .catch((e) => logger.log("Error creating todo: " + e));
    },
  })
);
```

### page/habits.js — Habits Page

```js
import * as hmUI from "@zos/ui";
import { log as Logger } from "@zos/utils";
import { BasePage } from "@zeppos/zml/base-page";
import { createKeyboard, inputType, deleteKeyboard } from "@zos/ui";
import {
  TITLE_TEXT, HABIT_AREA, ADD_BUTTON, LOADING_TEXT, EMPTY_TEXT, HABIT_ITEM_CONFIG,
} from "zosLoader:./habits.[pf].layout.js";

const logger = Logger.getLogger("habits_page");

Page(
  BasePage({
    state: { habits: [], scrollList: null, loadingWidget: null, emptyWidget: null },

    build() {
      hmUI.createWidget(hmUI.widget.TEXT, TITLE_TEXT);
      this.state.loadingWidget = hmUI.createWidget(hmUI.widget.TEXT, LOADING_TEXT);
      hmUI.createWidget(hmUI.widget.BUTTON, {
        ...ADD_BUTTON,
        click_func: () => this.showKeyboard(),
      });
      this.fetchHabits();
    },

    fetchHabits() {
      this.request({ method: "GET_HABITS" })
        .then((data) => {
          const habits = data.result || [];
          this.state.habits = habits;

          if (this.state.loadingWidget) {
            hmUI.deleteWidget(this.state.loadingWidget);
            this.state.loadingWidget = null;
          }

          if (habits.length === 0) {
            this.state.emptyWidget = hmUI.createWidget(hmUI.widget.TEXT, EMPTY_TEXT);
            return;
          }
          this.renderHabits(habits);
        })
        .catch((e) => logger.log("Error fetching habits: " + e));
    },

    renderHabits(habits) {
      if (this.state.emptyWidget) {
        hmUI.deleteWidget(this.state.emptyWidget);
        this.state.emptyWidget = null;
      }
      if (this.state.scrollList) {
        hmUI.deleteWidget(this.state.scrollList);
        this.state.scrollList = null;
      }

      const dataList = habits.map((habit) => {
        const progress = habit.current_progress || 0;
        const target = habit.target_count || 1;
        const icon = habit.icon || "⭐";
        const streak = habit.current_streak || 0;
        return {
          name: `${icon} ${habit.title || "Habit"}`,
          progress: `${progress}/${target}  🔥${streak}`,
        };
      });

      this.state.scrollList = hmUI.createWidget(hmUI.widget.SCROLL_LIST, {
        ...HABIT_AREA,
        item_config: [HABIT_ITEM_CONFIG],
        item_config_count: 1,
        data_array: dataList,
        data_count: dataList.length,
        data_type_config: [{ start: 0, end: dataList.length, type_id: 1 }],
        data_type_config_count: 1,
        item_click_func: (item, index) => {
          const habit = this.state.habits[index];
          if (habit) this.logHabit(habit);
        },
      });
    },

    logHabit(habit) {
      this.request({ method: "LOG_HABIT", params: { id: habit.id } })
        .then(() => this.fetchHabits())
        .catch((e) => logger.log("Error logging habit: " + e));
    },

    showKeyboard() {
      createKeyboard({
        inputType: inputType.NORMAL,
        onComplete: (_, result) => {
          const title = result.data;
          if (title && title.trim()) this.createHabit(title.trim());
          deleteKeyboard();
        },
        onCancel: () => deleteKeyboard(),
        text: "",
      });
    },

    createHabit(title) {
      this.request({ method: "CREATE_HABIT", params: { title } })
        .then(() => this.fetchHabits())
        .catch((e) => logger.log("Error creating habit: " + e));
    },
  })
);
```

### utils/config/constants.js — Colors and Config

```js
export const COLOR_PRIMARY = 0xbb86fc;
export const COLOR_PRIMARY_DARK = 0x8c5fcf;
export const COLOR_SUCCESS = 0x4caf50;
export const COLOR_SUCCESS_DARK = 0x388e3c;
export const COLOR_HABIT = 0xffab40;
export const COLOR_TEXT = 0xffffff;
export const COLOR_TEXT_DIM = 0x999999;
export const COLOR_TEXT_COMPLETED = 0x666666;
export const COLOR_BG_CARD = 0x1e1e2e;
export const COLOR_BG_CARD_PRESS = 0x2a2a3e;
export const COLOR_BG_DARK = 0x121218;
export const DIRECTUS_BASE_URL = 'https://api.opcw032522.uk';
export const USER_ID = 1;
export const DEFAULT_COLOR = COLOR_PRIMARY;
export const DEFAULT_COLOR_TRANSPARENT = COLOR_PRIMARY_DARK;
```

**Note:** Colors in ZeppOS are hex integers (0xRRGGBB), NOT CSS strings ("#RRGGBB"). CSS strings are only used in the settings page and in Directus data fields.

### utils/config/device.js — Device Dimensions

```js
import { getDeviceInfo } from "@zos/device";
export const { width: DEVICE_WIDTH, height: DEVICE_HEIGHT } = getDeviceInfo();
```

### Example Layout File: page/lists.s.layout.js (Square)

```js
import * as hmUI from "@zos/ui";
import { px } from "@zos/utils";
import { DEVICE_WIDTH, DEVICE_HEIGHT } from "../utils/config/device";
import {
  COLOR_PRIMARY, COLOR_PRIMARY_DARK, COLOR_TEXT, COLOR_TEXT_DIM, COLOR_BG_CARD,
} from "../utils/config/constants";

export const TITLE_TEXT = {
  x: 0, y: px(10), w: DEVICE_WIDTH, h: px(50),
  color: COLOR_TEXT, text_size: px(34),
  align_h: hmUI.align.CENTER_H, align_v: hmUI.align.CENTER_V,
  text: "My Lists",
};

export const LOADING_TEXT = {
  x: 0, y: px(160), w: DEVICE_WIDTH, h: px(50),
  color: COLOR_TEXT_DIM, text_size: px(26),
  align_h: hmUI.align.CENTER_H, align_v: hmUI.align.CENTER_V,
  text: "Loading...",
};

export const EMPTY_TEXT = {
  x: px(20), y: px(140), w: DEVICE_WIDTH - px(40), h: px(80),
  color: COLOR_TEXT_DIM, text_size: px(24),
  align_h: hmUI.align.CENTER_H, align_v: hmUI.align.CENTER_V,
  text: "No lists yet. Tap + to create one!",
  text_style: hmUI.text_style.WRAP,
};

export const LIST_AREA = {
  x: px(10), y: px(70), w: DEVICE_WIDTH - px(20), h: DEVICE_HEIGHT - px(160),
  item_space: px(6), snap_to_center: true,
};

export const ITEM_CONFIG = {
  type_id: 1,
  item_bg_color: COLOR_BG_CARD,
  item_bg_radius: px(12),
  item_height: px(60),
  text_view: [{
    x: px(16), y: px(0), w: DEVICE_WIDTH - px(60), h: px(60),
    key: "name", color: COLOR_TEXT, text_size: px(26), action: true,
  }],
  text_view_count: 1,
  image_view: [],
  image_view_count: 0,
};

const ADD_BTN_SIZE = px(56);
export const ADD_BUTTON = {
  x: (DEVICE_WIDTH - ADD_BTN_SIZE) / 2,
  y: DEVICE_HEIGHT - px(80),
  w: ADD_BTN_SIZE, h: ADD_BTN_SIZE,
  text_size: px(32), radius: px(28),
  normal_color: COLOR_PRIMARY, press_color: COLOR_PRIMARY_DARK,
  text: "+",
};
```

### package.json

```json
{
  "name": "fetch",
  "version": "1.0.0",
  "description": "",
  "main": "app.js",
  "scripts": {
    "test": "echo \"Error: no test specified\" && exit 1"
  },
  "author": "",
  "license": "ISC",
  "devDependencies": {
    "@zeppos/device-types": "^3.0.0"
  },
  "dependencies": {
    "@zeppos/zml": "^0.0.38"
  }
}
```

---

## Quick-Start Checklist for New ZeppOS API Apps

1. `npm i @nicegoodthings/zeus-cli -g`
2. `zeus create my-app` → choose ZML template with app-side (e.g., `fetch` or `helloworld3`)
3. Register app at console.zepp.com → get a real `appId`
4. Set `appId` in `app.json`
5. Set `platforms` to `[{ "st": "s" }]` (or `"r"`, or both) — NO `deviceSource` or `name`
6. Put `icon.png` in `assets/common.s/` and `assets/common.r/`
7. Write side service in `app-side/index.js` using `BaseSideService`
8. Use `this.fetch()` for HTTP, `this.log()` for logging, `onRequest()` for handling watch requests
9. Write watch pages using `BasePage` with `this.request()` to call side service
10. Use closure variables (not `this.state`) in `AppSettingsPage`
11. Keep IDs as strings — never `parseInt()`
12. `zeus build` → `zeus preview` for physical device
13. Check Side Service logs in Zepp app developer mode for debugging
