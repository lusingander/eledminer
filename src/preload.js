const home = require("../dst/home.js");
const menu = require("../dst/menu.js");
const settings = require("../dst/settings.js");
const { ipcRenderer } = require("electron");

window.home = home;
window.menu = menu;
window.settings = settings;
window.ipcRenderer = ipcRenderer;
