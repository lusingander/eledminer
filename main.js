const { app, BrowserWindow, BrowserView, ipcMain } = require("electron");

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

  const defaultWindowWidth = 1200;
  const defaultWindowHeight = 800;
  mainWindow = new BrowserWindow({
    width: defaultWindowWidth,
    height: defaultWindowHeight,
    useContentSize: true,
  });

  const menuView = new BrowserView({
    webPreferences: {
      preload: `${__dirname}/menu.js`,
    },
  });
  mainWindow.addBrowserView(menuView);

  const menuViewHeight = 40;
  menuView.setBounds({
    x: 0,
    y: 0,
    width: defaultWindowWidth,
    height: menuViewHeight,
  });
  menuView.setAutoResize({
    width: true,
  });
  menuView.webContents.loadURL("file://" + __dirname + "/menu.html");

  const mainView = new BrowserView();
  mainWindow.addBrowserView(mainView);

  mainView.setBounds({
    x: 0,
    y: menuViewHeight,
    width: defaultWindowWidth,
    height: defaultWindowHeight - menuViewHeight,
  });
  mainView.setAutoResize({
    width: true,
    height: true,
  });
  mainView.webContents.loadURL(`http://${server.host}:${server.port}`);

  mainWindow.on("closed", function() {
    server.close();
    mainWindow = null;
  });
}

ipcMain.on("HOME", () => {
  console.log("HOME");
});

ipcMain.on("SETTINGS", () => {
  console.log("SETTINGS");
});

app.on("activate", function() {
  if (mainWindow === null) {
    createWindow();
  }
});

app.on("ready", createWindow);
