const Store = require("electron-store");

class UserSettings {
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
}

class Connections {
  static load() {
    const store = new Store();
    return store.get("connections", []);
  }

  static save(conn) {
    const connections = Connections.load();
    connections.unshift(conn);
    const store = new Store();
    store.set("connections", connections);
  }
}

module.exports = {
  UserSettings: UserSettings,
  Connections: Connections,
};
