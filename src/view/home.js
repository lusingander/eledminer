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

ipcRenderer.on("OPEN_CONNECTION_COMPLETE", () => {
  app.ports.openConnectionComplete.send(null);
});

ipcRenderer.on("OPEN_CONNECTION_FAILURE", () => {
  app.ports.openConnectionFailure.send(null);
});

app.ports.saveNewConnection.subscribe((data) => {
  ipcRenderer.send("SAVE_NEW_CONNECTION", data);
});

ipcRenderer.on("SAVE_NEW_CONNECTION_SUCCESS", (_, args) => {
  app.ports.saveNewConnectionSuccess.send(args);
});

app.ports.saveEditConnection.subscribe((data) => {
  ipcRenderer.send("SAVE_EDIT_CONNECTION", data);
});

ipcRenderer.on("SAVE_EDIT_CONNECTION_SUCCESS", (_, args) => {
  app.ports.saveEditConnectionSuccess.send(args);
});

app.ports.removeConnection.subscribe((data) => {
  ipcRenderer.send("REMOVE_CONNECTION", data);
});

ipcRenderer.on("REMOVE_CONNECTION_SUCCESS", (_, args) => {
  app.ports.removeConnectionSuccess.send(args);
});

app.ports.openAdminerHome.subscribe((data) => {
  ipcRenderer.send("OPEN_ADMINER_HOME", data);
});
