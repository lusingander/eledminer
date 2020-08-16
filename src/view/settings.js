const { Elm } = require("../../dst/settings.js");
const { ipcRenderer } = require("electron");

const app = Elm.Settings.init({
  node: document.getElementById("elm"),
});

app.ports.documentLoaded.subscribe(function(data) {
  ipcRenderer.on("SETTINGS_LOADED_REPLY", (_, args) => {
    app.ports.loadSettings.send(args);
  });
  ipcRenderer.send("SETTINGS_LOADED");
});

app.ports.cancel.subscribe(function(data) {
  ipcRenderer.send("SETTINGS_CANCEL");
});

app.ports.restart.subscribe(function(data) {
  ipcRenderer.send("SETTINGS_SAVE", {
    settings: data,
    restart: true,
  });
});

app.ports.postpone.subscribe(function(data) {
  ipcRenderer.send("SETTINGS_SAVE", {
    settings: data,
    restart: false,
  });
});
