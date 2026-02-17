import * as hmUI from "@zos/ui";
import { log as Logger } from "@zos/utils";

import { BasePage } from "@zeppos/zml/base-page";
import { createKeyboard, inputType, deleteKeyboard } from "@zos/ui";
import {
    TITLE_TEXT,
    TASK_AREA,
    ADD_BUTTON,
    LOADING_TEXT,
    EMPTY_TEXT,
    TASK_ITEM_CONFIG,
    TASK_DONE_ITEM_CONFIG,
} from "zosLoader:./tasks.[pf].layout.js";

const logger = Logger.getLogger("tasks_page");

Page(
    BasePage({
        state: {
            todos: [],
            listId: null,
            listTitle: null,
            scrollList: null,
            loadingWidget: null,
            emptyWidget: null,
            titleWidget: null,
        },

        onInit(params) {
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
                click_func: () => {
                    this.showKeyboard();
                },
            });

            this.fetchTodos();

            this.request({
                method: "SET_LAST_PAGE",
                params: { route: "page/tasks", listId: this.state.listId, title: this.state.listTitle },
            }).catch(() => {});
        },

        fetchTodos() {
            const reqParams = {};
            if (this.state.listId) {
                reqParams.listId = this.state.listId;
            }

            this.request({ method: "GET_TODOS", params: reqParams })
                .then((data) => {
                    logger.log("Todos received: " + JSON.stringify(data));
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
                .catch((e) => {
                    logger.log("Error fetching todos: " + e);
                });
        },

        renderTodos(todos) {
            if (this.state.emptyWidget) {
                hmUI.deleteWidget(this.state.emptyWidget);
                this.state.emptyWidget = null;
            }

            if (todos.length === 0) {
                if (this.state.scrollList) {
                    hmUI.deleteWidget(this.state.scrollList);
                    this.state.scrollList = null;
                }
                this.state.emptyWidget = hmUI.createWidget(hmUI.widget.TEXT, EMPTY_TEXT);
                return;
            }

            const dataList = todos.map((todo) => ({
                checkbox_img: todo.is_completed ? "checkbox_checked.png" : "checkbox_unchecked.png",
                name: todo.title,
            }));

            const dataTypeConfig = todos.map((todo, i) => ({
                start: i,
                end: i + 1,
                type_id: todo.is_completed ? 2 : 1,
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
                    ...TASK_AREA,
                    item_config: [TASK_ITEM_CONFIG, TASK_DONE_ITEM_CONFIG],
                    item_config_count: 2,
                    data_array: dataList,
                    data_count: dataList.length,
                    data_type_config: dataTypeConfig,
                    data_type_config_count: dataTypeConfig.length,
                    item_click_func: (item, index) => {
                        const todo = this.state.todos[index];
                        if (todo) {
                            this.toggleTodo(todo);
                        }
                    },
                });
            }
        },

        toggleTodo(todo) {
            this.request({
                method: "TOGGLE_TODO",
                params: {
                    id: todo.id,
                    isCompleted: true,
                },
            })
                .then((data) => {
                    logger.log("Todo toggled: " + JSON.stringify(data));
                    todo.is_completed = true;
                    this.renderTodos(this.state.todos);
                    setTimeout(() => {
                        this.state.todos = this.state.todos.filter((t) => !t.is_completed);
                        this.renderTodos(this.state.todos);
                    }, 600);
                })
                .catch((e) => {
                    logger.log("Error toggling todo: " + e);
                });
        },

        showKeyboard() {
            createKeyboard({
                inputType: inputType.NORMAL,
                onComplete: (_, result) => {
                    const title = result.data;
                    if (title && title.trim()) {
                        this.createTodo(title.trim());
                    }
                    deleteKeyboard();
                },
                onCancel: () => {
                    deleteKeyboard();
                },
                text: "",
            });
        },

        createTodo(title) {
            const params = { title };
            if (this.state.listId) {
                params.listId = this.state.listId;
            }

            this.request({
                method: "CREATE_TODO",
                params,
            })
                .then((data) => {
                    logger.log("Todo created: " + JSON.stringify(data));
                    this.fetchTodos();
                })
                .catch((e) => {
                    logger.log("Error creating todo: " + e);
                });
        },
    })
);
