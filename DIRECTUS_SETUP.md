# Directus Setup Guide for TaskIt

This guide explains how to set up the Directus collections for the TaskIt app.

## Collections

### 1. `todos` Collection

| Field | Type | Notes |
|-------|------|-------|
| `id` | Integer (Auto-increment) | Primary Key |
| `title` | String | Required |
| `detail` | Text | Optional description |
| `is_completed` | Boolean | Default: false |
| `due_date` | DateTime | Optional |
| `duration` | Integer | Minutes, optional |
| `priority` | String | 'none', 'low', 'medium', 'high' |
| `list_id` | Integer (M2O) | Foreign key to `lists` |
| `recurring_frequency` | String | 'daily', 'weekly', 'monthly' (null = not recurring) |
| `repeat_interval` | Integer | Default: 1 (e.g., every 2 weeks) |
| `custom_recurring_days` | JSON (Dropdown Multiple) | Array of weekday numbers [1=Mon, 7=Sun] |
| `user_id` | Integer (M2O) | Foreign key to `users` |

---

### 2. `lists` Collection

| Field | Type | Notes |
|-------|------|-------|
| `id` | Integer (Auto-increment) | Primary Key |
| `title` | String | Required |
| `color` | String | Hex color code (e.g., '#BB86FC') |
| `user_id` | Integer (M2O) | Foreign key to `users` |

---

### 3. `users` Collection (Simple Auth)

| Field | Type | Notes |
|-------|------|-------|
| `id` | Integer | Primary Key - user-chosen login number |
| `name` | String | Optional display name |
| `created_at` | DateTime | Auto-set on create |

> **Note:** The app uses a simple numeric login system. Users enter their numeric ID to log in, which isolates their todos, habits, and lists. No password authentication is required by default.

---

### 4. `habits` Collection

| Field | Type | Notes |
|-------|------|-------|
| `id` | Integer (Auto-increment) | Primary Key |
| `title` | String | Required |
| `detail` | Text | Optional |
| `icon` | String | Emoji or icon name |
| `color` | String | Hex color |
| `target_count` | Integer | Goal per period (default: 1) |
| `current_progress` | Integer | Today's count (default: 0) |
| `frequency` | String | 'daily', 'weekly', 'monthly' |
| `repeat_interval` | Integer | Default: 1 |
| `goal_type` | String | 'daily' or 'period' (e.g. 3 times per week) |
| `custom_days` | JSON (Dropdown Multiple) | Array of weekday numbers [1=Mon, 7=Sun] |
| `current_streak` | Integer | Default: 0 |
| `best_streak` | Integer | Default: 0 |
| `last_completed` | DateTime | Last completion date |
| `created_at` | DateTime | Auto-set on create |
| `user_id` | Integer (M2O) | Foreign key to `users` |

---

### 5. `habit_logs` Collection

| Field | Type | Notes |
|-------|------|-------|
| `id` | Integer (Auto-increment) | Primary Key |
| `habit_id` | Integer (M2O) | Foreign key to `habits` |
| `date` | Date | When the habit was logged |
| `completed_count` | Integer | Number of completions |
| `notes` | Text | Optional notes |
| `created_at` | DateTime | Auto-set on create |

---

## Relationships

- `todos.list_id` → `lists.id` (Many-to-One)
- `todos.user_id` → `users.id` (Many-to-One)
- `lists.user_id` → `users.id` (Many-to-One)
- `habits.user_id` → `users.id` (Many-to-One)
- `habit_logs.habit_id` → `habits.id` (Many-to-One)

---

## Permissions

Set public read/write access for all collections, or configure authentication as needed.
