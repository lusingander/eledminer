const Elm = window.settings.Elm;
const ipcRenderer = window.ipcRenderer;

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

app.ports.verifyPhpExecutablePath.subscribe((data) => {
  ipcRenderer.send("VERIFY_PHP_EXECUTABLE_PATH", data);
});

ipcRenderer.on("VERIFY_PHP_EXECUTABLE_PATH_SUCCESS", (_, args) => {
  app.ports.verifyPhpExecutablePathSuccess.send(args);
});

app.ports.openPhpExecutablePathFileDialog.subscribe(() => {
  ipcRenderer.send("OPEN_PHP_EXECUTABLE_PATH_FILE_DIALOG");
});

ipcRenderer.on("OPEN_PHP_EXECUTABLE_PATH_FILE_DIALOG_SUCCESS", (_, args) => {
  app.ports.openPhpExecutablePathFileDialogSuccess.send(args);
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
