const electron = require("electron");
const app = electron.app;
const BrowserWindow = electron.BrowserWindow;
const BrowserView = electron.BrowserView;

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

  const w = 1200;
  const h = 800;
  mainWindow = new BrowserWindow({
    width: w,
    height: h,
    useContentSize: true,
  });

  const view = new BrowserView();
  mainWindow.addBrowserView(view);

  view.setBounds({
    x: 0,
    y: 0,
    width: w,
    height: h,
  });
  view.setAutoResize({
    width: true,
    height: true,
  });
  view.webContents.loadURL(`http://${server.host}:${server.port}`);

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
