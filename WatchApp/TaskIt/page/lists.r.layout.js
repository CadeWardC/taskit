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
    y: px(30),
    w: DEVICE_WIDTH,
    h: px(60),
    color: COLOR_TEXT,
    text_size: px(38),
    align_h: hmUI.align.CENTER_H,
    align_v: hmUI.align.CENTER_V,
    text: "My Lists",
};

export const LOADING_TEXT = {
    x: 0,
    y: px(200),
    w: DEVICE_WIDTH,
    h: px(60),
    color: COLOR_TEXT_DIM,
    text_size: px(28),
    align_h: hmUI.align.CENTER_H,
    align_v: hmUI.align.CENTER_V,
    text: "Loading...",
};

export const EMPTY_TEXT = {
    x: 0,
    y: px(200),
    w: DEVICE_WIDTH,
    h: px(60),
    color: COLOR_TEXT_DIM,
    text_size: px(28),
    align_h: hmUI.align.CENTER_H,
    align_v: hmUI.align.CENTER_V,
    text: "No lists yet. Tap + to create one!",
    text_style: hmUI.text_style.WRAP,
};

export const LIST_AREA = {
    x: px(20),
    y: px(100),
    w: DEVICE_WIDTH - px(40),
    h: DEVICE_HEIGHT - px(200),
    item_space: px(8),
    snap_to_center: true,
};

export const ITEM_CONFIG = {
    type_id: 1,
    item_bg_color: COLOR_BG_CARD,
    item_bg_radius: px(16),
    item_height: px(70),
    text_view: [
        {
            x: px(20),
            y: px(0),
            w: DEVICE_WIDTH - px(100),
            h: px(70),
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

const ADD_BTN_SIZE = px(64);

export const ADD_BUTTON = {
    x: (DEVICE_WIDTH - ADD_BTN_SIZE) / 2,
    y: DEVICE_HEIGHT - px(100),
    w: ADD_BTN_SIZE,
    h: ADD_BTN_SIZE,
    text_size: px(36),
    radius: px(32),
    normal_color: COLOR_PRIMARY,
    press_color: COLOR_PRIMARY_DARK,
    text: "+",
};
