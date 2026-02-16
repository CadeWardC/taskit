import { BaseApp } from "@zeppos/zml/base-app";

App(
  BaseApp({
    globalData: {},
    onCreate(options) {
      console.log("TaskIt app created");
    },

    onDestroy(options) {
      console.log("TaskIt app destroyed");
    },
  })
);
