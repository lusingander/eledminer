const { app, BrowserWindow, BrowserView, ipcMain } = require("electron");
const UserSettings = require("./store");
const PHPServer = require("php-server-manager");

const userSettings = UserSettings.load();
const server = new PHPServer({
  port: userSettings.port,
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
  const minWindowWidth = 600;
  const minWindowHeight = 400;
  const menuViewWidth = 50;

  const mainContentBounds = (w, h) => ({
    x: menuViewWidth,
    y: 0,
    width: w - menuViewWidth,
    height: h,
  });
  const menuContentBounds = (h) => ({
    x: 0,
    y: 0,
    width: menuViewWidth,
    height: h,
  });
  const zeroContentBounds = () => ({ x: 0, y: 0, width: 0, height: 0 });

  mainWindow = new BrowserWindow({
    width: defaultWindowWidth,
    height: defaultWindowHeight,
    useContentSize: true,
  });
  mainWindow.setMinimumSize(minWindowWidth, minWindowHeight);

  const menuView = new BrowserView({
    webPreferences: {
      preload: `${__dirname}/menu.js`,
    },
  });
  mainWindow.addBrowserView(menuView);

  menuView.setBounds(menuContentBounds(mainWindow.getContentSize()[1]));
  menuView.setAutoResize({
    height: true,
  });
  menuView.webContents.loadURL("file://" + __dirname + "/menu.html");

  const mainView = new BrowserView();
  mainWindow.addBrowserView(mainView);

  mainView.setBounds(mainContentBounds(...mainWindow.getContentSize()));
  mainView.setAutoResize({
    width: true,
    height: true,
  });
  mainView.webContents.loadURL(baseUrl);

  mainWindow.on("closed", function() {
    server.close();
    mainWindow = null;
  });

  let settingsView;
  const createSettingsView = () => {
    settingsView = new BrowserView({
      webPreferences: {
        preload: `${__dirname}/settings.js`,
      },
    });
    mainWindow.addBrowserView(settingsView);

    settingsView.setBounds(mainContentBounds(...mainWindow.getContentSize()));
    settingsView.setAutoResize({
      width: true,
      height: true,
    });
    settingsView.webContents.loadURL("file://" + __dirname + "/settings.html");
  };

  const openSettings = () => {
    if (!settingsView) {
      createSettingsView();
    }
    mainView.setBounds(zeroContentBounds());
  };

  const closeSettings = () => {
    if (settingsView) {
      mainWindow.removeBrowserView(settingsView);
      settingsView.destroy();
      settingsView = null;
    }
    mainView.setBounds(mainContentBounds(...mainWindow.getContentSize()));
  };

  ipcMain.on("HOME", () => {
    mainView.webContents.loadURL(baseUrl);
    closeSettings();
  });

  ipcMain.on("SETTINGS", () => {
    openSettings();
  });

  ipcMain.on("SETTINGS_LOADED", (event) => {
    event.reply("SETTINGS_LOADED_REPLY", UserSettings.load());
  });

  ipcMain.on("SETTINGS_SAVE", (event, args) => {
    UserSettings.save(args);
    event.reply("SETTINGS_SAVE_SUCCESS", UserSettings.load());
  });

  ipcMain.on("SETTINGS_CANCEL", () => {
    closeSettings();
  });
}

app.on("activate", function() {
  if (mainWindow === null) {
    createWindow();
  }
});

app.on("ready", createWindow);
