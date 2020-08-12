const { Elm } = require("./dst/settings.js");
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

app.ports.save.subscribe(function(data) {
  openConfirmModal();
});

app.ports.restart.subscribe(function(data) {
  closeConfirmModal();
  ipcRenderer.send("SETTINGS_SAVE", {
    settings: data,
    restart: true,
  });
});

app.ports.postpone.subscribe(function(data) {
  closeConfirmModal();
  ipcRenderer.send("SETTINGS_SAVE", {
    settings: data,
    restart: false,
  });
});

ipcRenderer.on("SETTINGS_SAVE_SUCCESS", () => {
  const not = document.querySelector("#save-success-notification");
  not.classList.add("notification-visible");
  setTimeout(function() {
    not.classList.remove("notification-visible");
  }, 4000);
});

const openConfirmModal = () => {
  const modal = findSaveConfirmModal();
  modal.classList.add("is-active");
};

const closeConfirmModal = () => {
  const modal = findSaveConfirmModal();
  modal.classList.remove("is-active");
};

const findSaveConfirmModal = () =>
  document.querySelector("#save-confirm-modal");
