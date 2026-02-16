import * as hmUI from "@zos/ui";
import { push } from "@zos/router";
import { localStorage } from "@zos/storage";
import { log as Logger } from "@zos/utils";
import { BasePage } from "@zeppos/zml/base-page";
import {
    TITLE_TEXT,
    MENU_AREA,
    MENU_ITEM_CONFIG,
} from "zosLoader:./index.[pf].layout.js";

const logger = Logger.getLogger("index_page");

const MENU_ITEMS = [
    { name: "📋  My Lists", route: "page/lists" },
    { name: "✅  All Tasks", route: "page/tasks" },
    { name: "🔥  Habits", route: "page/habits" },
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
                data_type_config: [
                    {
                        start: 0,
                        end: MENU_ITEMS.length,
                        type_id: 1,
                    },
                ],
                data_type_config_count: 1,
                item_click_func: (item, index) => {
                    const menuItem = MENU_ITEMS[index];
                    if (menuItem) {
                        logger.log("Navigate to: " + menuItem.route);
                        push({ url: menuItem.route });
                    }
                },
            });

            const saved = localStorage.getItem("lastPage");
            if (saved) {
                localStorage.removeItem("lastPage");
                try {
                    const { route, params } = JSON.parse(saved);
                    push({ url: route, params: params });
                } catch (e) {
                    logger.log("Failed to restore last page: " + e);
                }
            }
        },
    })
);
