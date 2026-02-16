import * as hmUI from "@zos/ui";
import { push } from "@zos/router";
import { log as Logger } from "@zos/utils";
import { localStorage } from "@zos/storage";
import { BasePage } from "@zeppos/zml/base-page";
import { createKeyboard, inputType, deleteKeyboard } from "@zos/ui";
import {
    TITLE_TEXT,
    LIST_AREA,
    ADD_BUTTON,
    LOADING_TEXT,
    EMPTY_TEXT,
    ITEM_CONFIG,
} from "zosLoader:./lists.[pf].layout.js";

const logger = Logger.getLogger("lists_page");

Page(
    BasePage({
        state: {
            lists: [],
            scrollList: null,
            loadingWidget: null,
            emptyWidget: null,
        },

        build() {
            hmUI.createWidget(hmUI.widget.TEXT, TITLE_TEXT);

            this.state.loadingWidget = hmUI.createWidget(hmUI.widget.TEXT, LOADING_TEXT);

            hmUI.createWidget(hmUI.widget.BUTTON, {
                ...ADD_BUTTON,
                click_func: () => {
                    this.showKeyboard();
                },
            });

            this.fetchLists();

            try {
                localStorage.setItem("lastPage", JSON.stringify({ route: "page/lists" }));
            } catch (e) {}
        },

        fetchLists() {
            this.request({ method: "GET_LISTS" })
                .then((data) => {
                    logger.log("Lists received: " + JSON.stringify(data));
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
                .catch((e) => {
                    logger.log("Error fetching lists: " + e);
                });
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

            const dataList = lists.map((list) => ({
                name: list.title || "Untitled List",
            }));

            this.state.scrollList = hmUI.createWidget(hmUI.widget.SCROLL_LIST, {
                ...LIST_AREA,
                item_config: [ITEM_CONFIG],
                item_config_count: 1,
                data_array: dataList,
                data_count: dataList.length,
                data_type_config: [
                    {
                        start: 0,
                        end: dataList.length,
                        type_id: 1,
                    },
                ],
                data_type_config_count: 1,
                item_click_func: (item, index) => {
                    const list = this.state.lists[index];
                    if (list) {
                        logger.log("Navigate to tasks for list: " + list.id);
                        push({
                            url: "page/tasks",
                            params: {
                                listId: list.id,
                                title: list.title,
                            },
                        });
                    }
                },
            });
        },

        showKeyboard() {
            createKeyboard({
                inputType: inputType.NORMAL,
                onComplete: (_, result) => {
                    const title = result.data;
                    if (title && title.trim()) {
                        this.createList(title.trim());
                    }
                    deleteKeyboard();
                },
                onCancel: () => {
                    deleteKeyboard();
                },
                text: "",
            });
        },

        createList(title) {
            this.request({
                method: "CREATE_LIST",
                params: { title },
            })
                .then((data) => {
                    logger.log("List created: " + JSON.stringify(data));
                    this.fetchLists();
                })
                .catch((e) => {
                    logger.log("Error creating list: " + e);
                });
        },
    })
);
