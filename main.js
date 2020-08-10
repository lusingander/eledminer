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
  const baseUrl = `http://${server.host}:${server.port}`;

  const defaultWindowWidth = 1200;
  const defaultWindowHeight = 800;
  const menuViewWidth = 50;

  const mainContentBounds = {
    x: menuViewWidth,
    y: 0,
    width: defaultWindowWidth - menuViewWidth,
    height: defaultWindowHeight,
  };
  const menuContentBounds = {
    x: 0,
    y: 0,
    width: menuViewWidth,
    height: defaultWindowHeight,
  };
  const zeroContentBounds = { x: 0, y: 0, width: 0, height: 0 };

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

  menuView.setBounds(menuContentBounds);
  menuView.setAutoResize({
    height: true,
  });
  menuView.webContents.loadURL("file://" + __dirname + "/menu.html");

  const settingsView = new BrowserView({
    webPreferences: {
      preload: `${__dirname}/settings.js`,
    },
  });
  mainWindow.addBrowserView(settingsView);

  settingsView.setBounds(zeroContentBounds);
  settingsView.setAutoResize({
    width: true,
    height: true,
  });
  settingsView.webContents.loadURL("file://" + __dirname + "/settings.html");

  const mainView = new BrowserView();
  mainWindow.addBrowserView(mainView);

  mainView.setBounds(mainContentBounds);
  mainView.setAutoResize({
    width: true,
    height: true,
  });
  mainView.webContents.loadURL(baseUrl);

  mainWindow.on("closed", function() {
    server.close();
    mainWindow = null;
  });

  ipcMain.on("HOME", () => {
    mainView.webContents.loadURL(baseUrl);
    mainView.setBounds(mainContentBounds);
    settingsView.setBounds(zeroContentBounds);
  });

  ipcMain.on("SETTINGS", () => {
    settingsView.setBounds(mainContentBounds);
    mainView.setBounds(zeroContentBounds);
  });
}

app.on("activate", function() {
  if (mainWindow === null) {
    createWindow();
  }
});

app.on("ready", createWindow);
