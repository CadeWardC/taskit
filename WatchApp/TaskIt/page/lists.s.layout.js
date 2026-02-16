import * as hmUI from "@zos/ui";
import { px } from "@zos/utils";
import { DEVICE_WIDTH, DEVICE_HEIGHT } from "../utils/config/device";
import {
    COLOR_PRIMARY,
    COLOR_PRIMARY_DARK,
    COLOR_TEXT,
    COLOR_TEXT_DIM,
    COLOR_BG_CARD,
    COLOR_BG_CARD_PRESS,
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
    text: "My Lists",
};

export const LOADING_TEXT = {
    x: 0,
    y: px(160),
    w: DEVICE_WIDTH,
    h: px(50),
    color: COLOR_TEXT_DIM,
    text_size: px(26),
    align_h: hmUI.align.CENTER_H,
    align_v: hmUI.align.CENTER_V,
    text: "Loading...",
};

export const EMPTY_TEXT = {
    x: px(20),
    y: px(140),
    w: DEVICE_WIDTH - px(40),
    h: px(80),
    color: COLOR_TEXT_DIM,
    text_size: px(24),
    align_h: hmUI.align.CENTER_H,
    align_v: hmUI.align.CENTER_V,
    text: "No lists yet. Tap + to create one!",
    text_style: hmUI.text_style.WRAP,
};

export const LIST_AREA = {
    x: px(10),
    y: px(70),
    w: DEVICE_WIDTH - px(20),
    h: DEVICE_HEIGHT - px(160),
    item_space: px(6),
    snap_to_center: true,
};

export const ITEM_CONFIG = {
    type_id: 1,
    item_bg_color: COLOR_BG_CARD,
    item_bg_radius: px(12),
    item_height: px(60),
    text_view: [
        {
            x: px(16),
            y: px(0),
            w: DEVICE_WIDTH - px(60),
            h: px(60),
            key: "name",
            color: COLOR_TEXT,
            text_size: px(26),
            action: true,
        },
    ],
    text_view_count: 1,
    image_view: [],
    image_view_count: 0,
};

const ADD_BTN_SIZE = px(56);

export const ADD_BUTTON = {
    x: (DEVICE_WIDTH - ADD_BTN_SIZE) / 2,
    y: DEVICE_HEIGHT - px(80),
    w: ADD_BTN_SIZE,
    h: ADD_BTN_SIZE,
    text_size: px(32),
    radius: px(28),
    normal_color: COLOR_PRIMARY,
    press_color: COLOR_PRIMARY_DARK,
    text: "+",
};
