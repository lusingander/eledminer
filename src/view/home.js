const { Elm } = require("../../dst/home.js");
const { ipcRenderer } = require("electron");

const app = Elm.Home.init({
  node: document.getElementById("elm"),
});

app.ports.openConnection.subscribe((data) => {
  ipcRenderer.send("OPEN_CONNECTION", data);
});
