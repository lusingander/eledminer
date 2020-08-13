const Store = require("electron-store");

module.exports = class UserSettings {
  static load() {
    const store = new Store();
    return new UserSettings({
      port: store.get("general.port", 8000),
      theme: store.get("appearance.theme", "default"),
    });
  }

  static save(params) {
    const store = new Store();
    store.set("general.port", params.port);
    store.set("appearance.theme", params.theme);
  }

  constructor(params) {
    this.port = params.port;
    this.theme = params.theme;
  }
};
