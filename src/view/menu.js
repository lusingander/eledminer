const { Elm } = require("../../dst/menu.js");
const { ipcRenderer } = require("electron");

const app = Elm.Menu.init({
  node: document.getElementById("elm"),
});

app.ports.home.subscribe(() => {
  ipcRenderer.send("HOME");
});

app.ports.settings.subscribe(() => {
  ipcRenderer.send("SETTINGS");
});
