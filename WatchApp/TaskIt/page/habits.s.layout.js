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
    COLOR_SUCCESS,
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
    text: "Habits",
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
    x: px(10),
    y: px(140),
    w: DEVICE_WIDTH - px(20),
    h: px(70),
    color: COLOR_TEXT_DIM,
    text_size: px(24),
    align_h: hmUI.align.CENTER_H,
    align_v: hmUI.align.CENTER_V,
    text: "No habits yet. Tap + to add!",
    text_style: hmUI.text_style.WRAP,
};

export const HABIT_AREA = {
    x: px(10),
    y: px(70),
    w: DEVICE_WIDTH - px(20),
    h: DEVICE_HEIGHT - px(160),
    item_space: px(6),
    snap_to_center: true,
};

export const HABIT_ITEM_CONFIG = {
    type_id: 1,
    item_bg_color: COLOR_BG_CARD,
    item_bg_radius: px(12),
    item_height: px(76),
    text_view: [
        {
            x: px(44),
            y: px(6),
            w: DEVICE_WIDTH - px(80),
            h: px(36),
            key: "name",
            color: COLOR_TEXT,
            text_size: px(24),
            action: true,
        },
        {
            x: px(44),
            y: px(40),
            w: DEVICE_WIDTH - px(80),
            h: px(30),
            key: "progress",
            color: COLOR_HABIT,
            text_size: px(20),
        },
    ],
    text_view_count: 2,
    image_view: [
        {
            x: px(10),
            y: px(24),
            w: px(28),
            h: px(28),
            key: "checkbox_img",
        },
    ],
    image_view_count: 1,
};

export const HABIT_DONE_ITEM_CONFIG = {
    type_id: 2,
    item_bg_color: 0x162016,
    item_bg_radius: px(12),
    item_height: px(76),
    text_view: [
        {
            x: px(44),
            y: px(6),
            w: DEVICE_WIDTH - px(80),
            h: px(36),
            key: "name",
            color: COLOR_SUCCESS,
            text_size: px(24),
            action: true,
        },
        {
            x: px(44),
            y: px(40),
            w: DEVICE_WIDTH - px(80),
            h: px(30),
            key: "progress",
            color: COLOR_SUCCESS,
            text_size: px(20),
        },
    ],
    text_view_count: 2,
    image_view: [
        {
            x: px(10),
            y: px(24),
            w: px(28),
            h: px(28),
            key: "checkbox_img",
        },
    ],
    image_view_count: 1,
};

const ADD_BTN_SIZE = px(56);

export const ADD_BUTTON = {
    x: (DEVICE_WIDTH - ADD_BTN_SIZE) / 2,
    y: DEVICE_HEIGHT - px(80),
    w: ADD_BTN_SIZE,
    h: ADD_BTN_SIZE,
    text_size: px(32),
    radius: px(28),
    normal_color: COLOR_HABIT,
    press_color: COLOR_PRIMARY_DARK,
    text: "+",
};
