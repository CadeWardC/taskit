import * as hmUI from "@zos/ui";
import { log as Logger } from "@zos/utils";

import { BasePage } from "@zeppos/zml/base-page";
import { createKeyboard, inputType, deleteKeyboard } from "@zos/ui";
import {
    TITLE_TEXT,
    HABIT_AREA,
    ADD_BUTTON,
    LOADING_TEXT,
    EMPTY_TEXT,
    HABIT_ITEM_CONFIG,
    HABIT_DONE_ITEM_CONFIG,
} from "zosLoader:./habits.[pf].layout.js";

const logger = Logger.getLogger("habits_page");

Page(
    BasePage({
        state: {
            habits: [],
            scrollList: null,
            loadingWidget: null,
            emptyWidget: null,
        },

        build() {
            // Title
            hmUI.createWidget(hmUI.widget.TEXT, TITLE_TEXT);

            // Loading
            this.state.loadingWidget = hmUI.createWidget(hmUI.widget.TEXT, LOADING_TEXT);

            // Add button
            hmUI.createWidget(hmUI.widget.BUTTON, {
                ...ADD_BUTTON,
                click_func: () => {
                    this.showKeyboard();
                },
            });

            // Fetch habits
            this.fetchHabits();

            this.request({
                method: "SET_LAST_PAGE",
                params: { route: "page/habits" },
            }).catch(() => {});
        },

        fetchHabits() {
            this.request({ method: "GET_HABITS" })
                .then((data) => {
                    logger.log("Habits received: " + JSON.stringify(data));
                    const habits = (data.result || []).filter(
                        (h) => (h.current_progress || 0) < (h.target_count || 1)
                    );
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
                .catch((e) => {
                    logger.log("Error fetching habits: " + e);
                });
        },

        renderHabits(habits) {
            if (this.state.emptyWidget) {
                hmUI.deleteWidget(this.state.emptyWidget);
                this.state.emptyWidget = null;
            }

            if (habits.length === 0) {
                if (this.state.scrollList) {
                    hmUI.deleteWidget(this.state.scrollList);
                    this.state.scrollList = null;
                }
                this.state.emptyWidget = hmUI.createWidget(hmUI.widget.TEXT, EMPTY_TEXT);
                return;
            }

            const dataList = habits.map((habit) => {
                const progress = habit.current_progress || 0;
                const target = habit.target_count || 1;
                const icon = habit.icon || "⭐";
                const streak = habit.current_streak || 0;
                const done = progress >= target;

                return {
                    checkbox_img: done ? "checkbox_checked.png" : "checkbox_unchecked.png",
                    name: `${icon} ${habit.title || "Habit"}`,
                    progress: `${progress}/${target}  🔥${streak}`,
                };
            });

            const dataTypeConfig = habits.map((habit, i) => ({
                start: i,
                end: i + 1,
                type_id: (habit.current_progress || 0) >= (habit.target_count || 1) ? 2 : 1,
            }));

            if (this.state.scrollList) {
                this.state.scrollList.setProperty(hmUI.prop.UPDATE_DATA, {
                    data_type_config: dataTypeConfig,
                    data_type_config_count: dataTypeConfig.length,
                    data_array: dataList,
                    data_count: dataList.length,
                    on_page: 1,
                });
            } else {
                this.state.scrollList = hmUI.createWidget(hmUI.widget.SCROLL_LIST, {
                    ...HABIT_AREA,
                    item_config: [HABIT_ITEM_CONFIG, HABIT_DONE_ITEM_CONFIG],
                    item_config_count: 2,
                    data_array: dataList,
                    data_count: dataList.length,
                    data_type_config: dataTypeConfig,
                    data_type_config_count: dataTypeConfig.length,
                    item_click_func: (item, index) => {
                        const habit = this.state.habits[index];
                        if (habit) {
                            this.logHabit(habit);
                        }
                    },
                });
            }
        },

        logHabit(habit) {
            this.request({
                method: "LOG_HABIT",
                params: { id: habit.id },
            })
                .then((data) => {
                    logger.log("Habit logged: " + JSON.stringify(data));
                    const updated = data.result;
                    if (updated) {
                        Object.assign(habit, updated);
                    }
                    this.renderHabits(this.state.habits);

                    const done = (habit.current_progress || 0) >= (habit.target_count || 1);
                    if (done) {
                        setTimeout(() => {
                            this.state.habits = this.state.habits.filter(
                                (h) => (h.current_progress || 0) < (h.target_count || 1)
                            );
                            this.renderHabits(this.state.habits);
                        }, 600);
                    }
                })
                .catch((e) => {
                    logger.log("Error logging habit: " + e);
                });
        },

        showKeyboard() {
            createKeyboard({
                inputType: inputType.NORMAL,
                onComplete: (_, result) => {
                    const title = result.data;
                    if (title && title.trim()) {
                        this.createHabit(title.trim());
                    }
                    deleteKeyboard();
                },
                onCancel: () => {
                    deleteKeyboard();
                },
                text: "",
            });
        },

        createHabit(title) {
            this.request({
                method: "CREATE_HABIT",
                params: { title },
            })
                .then((data) => {
                    logger.log("Habit created: " + JSON.stringify(data));
                    this.fetchHabits();
                })
                .catch((e) => {
                    logger.log("Error creating habit: " + e);
                });
        },
    })
);
