const { ipcRenderer } = require("electron");

document.addEventListener("DOMContentLoaded", function() {
  const saveButton = document.querySelector("#save-btn");
  saveButton.addEventListener("click", function(e) {
    ipcRenderer.send("SETTINGS_SAVE");
  });

  const cancelButton = document.querySelector("#cancel-btn");
  cancelButton.addEventListener("click", function(e) {
    ipcRenderer.send("SETTINGS_CANCEL");
  });
});
