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
    const modal = document.querySelector("#save-confirm-modal");
    modal.classList.add("is-active");
  });
  ipcRenderer.on("SETTINGS_SAVE_SUCCESS", () => {
    const not = document.querySelector("#save-success-notification");
    not.classList.add("notification-visible");
    setTimeout(function() {
      not.classList.remove("notification-visible");
    }, 4000);
  });

  const restartButton = document.querySelector("#save-confirm-restart");
  restartButton.addEventListener("click", function(e) {
    const modal = document.querySelector("#save-confirm-modal");
    modal.classList.remove("is-active");
    ipcRenderer.send("SETTINGS_SAVE", {
      settings: getUserSettings(),
      restart: true,
    });
  });

  const postponeButton = document.querySelector("#save-confirm-postpone");
  postponeButton.addEventListener("click", function(e) {
    const modal = document.querySelector("#save-confirm-modal");
    modal.classList.remove("is-active");
    ipcRenderer.send("SETTINGS_SAVE", {
      settings: getUserSettings(),
      restart: false,
    });
  });

  const cancelButton = document.querySelector("#cancel-btn");
  cancelButton.addEventListener("click", function(e) {
    ipcRenderer.send("SETTINGS_CANCEL");
  });
});
