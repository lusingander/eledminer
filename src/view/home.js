const { Elm } = require("../../dst/home.js");
const { ipcRenderer } = require("electron");

const app = Elm.Home.init({
  node: document.getElementById("elm"),
});

app.ports.openConnection.subscribe((data) => {
  ipcRenderer.send("OPEN_CONNECTION", data);
});

app.ports.saveNewConnection.subscribe((data) => {
  ipcRenderer.send("SAVE_NEW_CONNECTION", data);
});

ipcRenderer.on("SAVE_NEW_CONNECTION_SUCCESS", () => {
  app.ports.saveNewConnectionSuccess.send(null);
});
