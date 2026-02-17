import { BaseSideService } from "@zeppos/zml/base-side";
import { settingsLib } from "@zeppos/zml/base-side";

const BASE_URL = "https://api.opcw032522.uk";
const DEFAULT_USER_ID = "1";

AppSideService(
  BaseSideService({
    onInit() {
      this.log("TaskIt side service initialized");
    },

    getUserId() {
      try {
        const stored = settingsLib.getItem("userId");
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

      if (body) {
        options.body = JSON.stringify(body);
      }

      this.log("fetchDirectus:", method, options.url);

      try {
        const response = await this.fetch(options);
        this.log("fetchDirectus response status:", response.status);
        this.log("fetchDirectus response body type:", typeof response.body);
        this.log("fetchDirectus response body:", JSON.stringify(response.body).substring(0, 200));

        const resBody =
          typeof response.body === "string"
            ? JSON.parse(response.body)
            : response.body;

        this.log("fetchDirectus parsed data keys:", Object.keys(resBody || {}));
        return resBody;
      } catch (e) {
        this.log("fetchDirectus FETCH ERROR:", e.message || String(e));
        throw e;
      }
    },

    onSettingsChange({ key, newValue, oldValue }) {
      this.log("Settings changed:", key, newValue);
      if (key === "userId" && newValue) {
        this.log("User ID updated from settings:", newValue);
      }
    },

    onRequest(req, res) {
      const userId = this.getUserId();
      this.log("Side service request:", req.method, "userId:", userId);

      switch (req.method) {
        case "GET_LISTS":
          this.fetchDirectus(
            "/items/lists?filter[user_id][_eq]=" + userId
          )
            .then((data) => {
              res(null, { result: data.data || [] });
            })
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
          path += "&filter[is_completed][_eq]=false&sort=title";
          this.fetchDirectus(path)
            .then((data) => {
              res(null, { result: data.data || [] });
            })
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
            .then((data) => {
              res(null, { result: data.data || [] });
            })
            .catch((e) => {
              this.log("GET_HABITS error:", e);
              res(null, { result: [], error: String(e) });
            });
          break;

        case "CREATE_LIST":
          this.fetchDirectus("/items/lists", "POST", {
            title: req.params.title,
            color: req.params.color || "#BB86FC",
            user_id: userId,
          })
            .then((data) => {
              res(null, { result: data.data });
            })
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
            .then((data) => {
              res(null, { result: data.data });
            })
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
            .then((data) => {
              res(null, { result: data.data });
            })
            .catch((e) => {
              this.log("CREATE_HABIT error:", e);
              res(null, { result: null, error: String(e) });
            });
          break;

        case "TOGGLE_TODO":
          this.fetchDirectus(
            "/items/todos/" + req.params.id,
            "PATCH",
            { is_completed: req.params.isCompleted }
          )
            .then((data) => {
              res(null, { result: data.data });
            })
            .catch((e) => {
              this.log("TOGGLE_TODO error:", e);
              res(null, { result: null, error: String(e) });
            });
          break;

        case "DELETE_TODO":
          this.fetchDirectus("/items/todos/" + req.params.id, "DELETE")
            .then(() => {
              res(null, { result: true });
            })
            .catch((e) => {
              this.log("DELETE_TODO error:", e);
              res(null, { result: false, error: String(e) });
            });
          break;

        case "DELETE_LIST":
          this.fetchDirectus("/items/lists/" + req.params.id, "DELETE")
            .then(() => {
              res(null, { result: true });
            })
            .catch((e) => {
              this.log("DELETE_LIST error:", e);
              res(null, { result: false, error: String(e) });
            });
          break;

        case "DELETE_HABIT":
          this.fetchDirectus("/items/habits/" + req.params.id, "DELETE")
            .then(() => {
              res(null, { result: true });
            })
            .catch((e) => {
              this.log("DELETE_HABIT error:", e);
              res(null, { result: false, error: String(e) });
            });
          break;

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

        case "SET_LAST_PAGE":
          try {
            settingsLib.setItem("lastPage", JSON.stringify(req.params));
            res(null, { result: true });
          } catch (e) {
            this.log("SET_LAST_PAGE error:", e);
            res(null, { result: false });
          }
          break;

        case "GET_LAST_PAGE":
          try {
            const raw = settingsLib.getItem("lastPage");
            res(null, { result: raw ? JSON.parse(raw) : null });
          } catch (e) {
            this.log("GET_LAST_PAGE error:", e);
            res(null, { result: null });
          }
          break;

        default:
          res(null, { result: null, error: "Unknown method" });
      }
    },

    handleLogHabit(req, res, userId) {
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

          return this.fetchDirectus(
            "/items/habits/" + req.params.id,
            "PATCH",
            updateData
          );
        })
        .then((updated) => {
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
