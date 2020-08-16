const { app, BrowserWindow, BrowserView, ipcMain } = require("electron");
const { UserSettings, Connections } = require("./src/store");
const PHPServer = require("php-server-manager");
const { loginAndGetConnectionInfo } = require("./src/adminer");

const userSettings = UserSettings.load();
const server = new PHPServer({
  port: userSettings.port,
  directory: __dirname,
  directives: {
    display_errors: 1,
    expose_php: 1,
  },
  env: {
    ELEDMINER_SETTINGS_THEME: userSettings.theme,
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
      nodeIntegration: true,
    },
  });
  mainWindow.addBrowserView(menuView);

  menuView.setBounds(menuContentBounds(mainWindow.getContentSize()[1]));
  menuView.setAutoResize({
    height: true,
  });
  menuView.webContents.loadURL("file://" + __dirname + "/src/view/menu.html");

  const homeView = new BrowserView({
    webPreferences: {
      nodeIntegration: true,
    },
  });
  mainWindow.addBrowserView(homeView);
  homeView.setBounds(mainContentBounds(...mainWindow.getContentSize()));
  homeView.setAutoResize({
    width: true,
    height: true,
  });
  const homeUrl = "file://" + __dirname + "/src/view/home.html";
  homeView.webContents.loadURL(homeUrl);

  const mainView = new BrowserView();
  mainWindow.addBrowserView(mainView);

  mainView.setBounds(zeroContentBounds());
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
        nodeIntegration: true,
      },
    });
    mainWindow.addBrowserView(settingsView);

    settingsView.setBounds(mainContentBounds(...mainWindow.getContentSize()));
    settingsView.setAutoResize({
      width: true,
      height: true,
    });
    settingsView.webContents.loadURL(
      "file://" + __dirname + "/src/view/settings.html"
    );
  };

  const openSettings = () => {
    if (!settingsView) {
      createSettingsView();
    }
    mainView.setBounds(zeroContentBounds());
    homeView.setBounds(zeroContentBounds());
  };

  const closeSettings = () => {
    if (settingsView) {
      mainWindow.removeBrowserView(settingsView);
      settingsView.destroy();
      settingsView = null;
    }
    mainView.setBounds(zeroContentBounds());
    homeView.setBounds(mainContentBounds(...mainWindow.getContentSize()));
  };

  const openAdminerView = () => {
    homeView.setBounds(zeroContentBounds());
    mainView.setBounds(mainContentBounds(...mainWindow.getContentSize()));
  };

  ipcMain.on("HOME", () => {
    mainView.webContents.loadURL(homeUrl);
    closeSettings();
  });

  ipcMain.on("SETTINGS", () => {
    openSettings();
  });

  ipcMain.on("HOME_LOADED", (event) => {
    event.reply("HOME_LOADED_REPLY", Connections.load());
  });

  ipcMain.on("SETTINGS_LOADED", (event) => {
    event.reply("SETTINGS_LOADED_REPLY", UserSettings.load());
  });

  ipcMain.on("SETTINGS_SAVE", (event, args) => {
    UserSettings.save(args.settings);
    if (args.restart) {
      app.relaunch();
      app.exit();
    }
  });

  ipcMain.on("SETTINGS_CANCEL", () => {
    closeSettings();
  });

  ipcMain.on("OPEN_CONNECTION", (event, args) => {
    loginAndGetConnectionInfo({
      baseUrl: `http://localhost:${userSettings.port}/`,
      driver: args.driver,
      server: `${args.hostname}:${args.port}`,
      username: args.username,
      password: args.password,
    })
      .then((result) =>
        mainWindow.webContents.session.cookies
          .set(result.cookie)
          .then(() => mainView.webContents.loadURL(result.redirectUrl))
      )
      // dont want to open adminer view if not 200... (return 403 if parmaeter is invalid)
      .then(() => openAdminerView())
      .catch((err) => console.log(`failed connecting database: ${err}`));
  });

  ipcMain.on("SAVE_NEW_CONNECTION", (event, args) => {
    const newConnection = {
      type: "default",
      driver: args.driver,
      name: args.name,
      hostname: args.hostname,
      port: args.port,
      username: args.username,
      password: args.password,
    };
    Connections.save(newConnection);
    event.reply("SAVE_NEW_CONNECTION_SUCCESS", newConnection);
  });
}

app.on("activate", function() {
  if (mainWindow === null) {
    createWindow();
  }
});

app.on("ready", createWindow);
