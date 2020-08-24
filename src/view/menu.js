const Elm = window.menu.Elm;
const ipcRenderer = window.ipcRenderer;

const app = Elm.Menu.init({
  node: document.getElementById("elm"),
});

app.ports.home.subscribe(() => {
  ipcRenderer.send("HOME");
});

app.ports.settings.subscribe(() => {
  ipcRenderer.send("SETTINGS");
});
