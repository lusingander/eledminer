const electron = require("electron");
const app = electron.app;
const BrowserWindow = electron.BrowserWindow;

const PHPServer = require("php-server-manager");

const server = new PHPServer({
  port: 8000,
  directory: __dirname,
  directives: {
    display_errors: 1,
    expose_php: 1,
  },
});

let mainWindow;

app.on("window-all-closed", function() {
  if (process.platform !== "darwin") {
    server.close();
    app.quit();
  }
});

function createWindow() {
  server.run();

  mainWindow = new BrowserWindow({ width: 1200, height: 800 });
  mainWindow.loadURL(`http://${server.host}:${server.port}`);

  mainWindow.on("closed", function() {
    server.close();
    mainWindow = null;
  });
}

app.on("activate", function() {
  if (mainWindow === null) {
    createWindow();
  }
});

app.on("ready", createWindow);
