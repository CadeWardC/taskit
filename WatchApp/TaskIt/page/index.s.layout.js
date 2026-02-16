import * as hmUI from "@zos/ui";
import { px } from "@zos/utils";
import { DEVICE_WIDTH, DEVICE_HEIGHT } from "../utils/config/device";
import {
    COLOR_PRIMARY,
    COLOR_PRIMARY_DARK,
    COLOR_HABIT,
    COLOR_TEXT,
    COLOR_TEXT_DIM,
    COLOR_BG_CARD,
} from "../utils/config/constants";

export const TITLE_TEXT = {
    x: 0,
    y: px(10),
    w: DEVICE_WIDTH,
    h: px(50),
    color: COLOR_TEXT,
    text_size: px(34),
    align_h: hmUI.align.CENTER_H,
    align_v: hmUI.align.CENTER_V,
    text: "TaskIt",
};

export const MENU_AREA = {
    x: px(10),
    y: px(70),
    w: DEVICE_WIDTH - px(20),
    h: DEVICE_HEIGHT - px(90),
    item_space: px(8),
    snap_to_center: true,
};

export const MENU_ITEM_CONFIG = {
    type_id: 1,
    item_bg_color: COLOR_BG_CARD,
    item_bg_radius: px(14),
    item_height: px(72),
    text_view: [
        {
            x: px(20),
            y: px(0),
            w: DEVICE_WIDTH - px(60),
            h: px(72),
            key: "name",
            color: COLOR_TEXT,
            text_size: px(28),
            action: true,
        },
    ],
    text_view_count: 1,
    image_view: [],
    image_view_count: 0,
};
