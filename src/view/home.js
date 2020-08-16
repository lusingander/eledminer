const { Elm } = require("../../dst/home.js");
const { ipcRenderer } = require("electron");

const app = Elm.Home.init({
  node: document.getElementById("elm"),
});

app.ports.loaded.subscribe(() => {
  ipcRenderer.on("HOME_LOADED_REPLY", (_, args) => {
    app.ports.loadConnections.send(args);
  });
  ipcRenderer.send("HOME_LOADED");
});

app.ports.openConnection.subscribe((data) => {
  ipcRenderer.send("OPEN_CONNECTION", data);
});

app.ports.saveNewConnection.subscribe((data) => {
  ipcRenderer.send("SAVE_NEW_CONNECTION", data);
});

ipcRenderer.on("SAVE_NEW_CONNECTION_SUCCESS", (_, args) => {
  app.ports.saveNewConnectionSuccess.send(args);
});
