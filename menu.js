const { ipcRenderer } = require("electron");

document.addEventListener("DOMContentLoaded", function() {
  const homeButton = document.querySelector("#home-btn");
  homeButton.addEventListener("click", function(e) {
    ipcRenderer.send("HOME");
  });

  const settingsButton = document.querySelector("#settings-btn");
  settingsButton.addEventListener("click", function(e) {
    ipcRenderer.send("SETTINGS");
  });
});
