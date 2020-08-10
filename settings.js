const { ipcRenderer } = require("electron");

const setUserSettings = (s) => {
  document.querySelector("#general-port").value = s.port;
  document.querySelector("#appearance-theme").value = s.theme;
};

const getUserSettings = () => ({
  port: Number(document.querySelector("#general-port").value),
  theme: document.querySelector("#appearance-theme").value,
});

document.addEventListener("DOMContentLoaded", function() {
  ipcRenderer.on("SETTINGS_LOADED_REPLY", (_, args) => {
    setUserSettings(args);
  });
  ipcRenderer.send("SETTINGS_LOADED");

  const saveButton = document.querySelector("#save-btn");
  saveButton.addEventListener("click", function(e) {
    // confirm: restart
    ipcRenderer.send("SETTINGS_SAVE", getUserSettings());
  });

  const cancelButton = document.querySelector("#cancel-btn");
  cancelButton.addEventListener("click", function(e) {
    ipcRenderer.send("SETTINGS_CANCEL");
  });
});
