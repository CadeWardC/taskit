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
    y: px(30),
    w: DEVICE_WIDTH,
    h: px(60),
    color: COLOR_TEXT,
    text_size: px(38),
    align_h: hmUI.align.CENTER_H,
    align_v: hmUI.align.CENTER_V,
    text: "TaskIt",
};

export const MENU_AREA = {
    x: px(20),
    y: px(100),
    w: DEVICE_WIDTH - px(40),
    h: DEVICE_HEIGHT - px(140),
    item_space: px(10),
    snap_to_center: true,
};

export const MENU_ITEM_CONFIG = {
    type_id: 1,
    item_bg_color: COLOR_BG_CARD,
    item_bg_radius: px(16),
    item_height: px(80),
    text_view: [
        {
            x: px(24),
            y: px(0),
            w: DEVICE_WIDTH - px(88),
            h: px(80),
            key: "name",
            color: COLOR_TEXT,
            text_size: px(30),
            action: true,
        },
    ],
    text_view_count: 1,
    image_view: [],
    image_view_count: 0,
};
