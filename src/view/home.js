const Elm = window.home.Elm;
const ipcRenderer = window.ipcRenderer;

const app = Elm.Home.init({
  node: document.getElementById("elm"),
});

app.ports.loaded.subscribe(() => {
  ipcRenderer.send("HOME_LOADED");
});

ipcRenderer.on("HOME_LOADED_REPLY", (_, args) => {
  app.ports.loadConnections.send(args);
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

app.ports.openSqliteFileDialog.subscribe((data) => {
  ipcRenderer.send("OPEN_SQLITE_FILE_DIALOG", data);
});

ipcRenderer.on("OPEN_SQLITE_FILE_DIALOG_SUCCESS", (_, args) => {
  app.ports.openSqliteFileDialogSuccess.send(args);
});

ipcRenderer.on("PHP_SERVER_NOT_RUNNING", () => {
  app.ports.phpServerNotRunning.send(null);
});
