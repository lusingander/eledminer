const Store = require("electron-store");

module.exports = {
  UserSettings: class UserSettings {
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
  },

  Connections: class Connections {
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

    static update(conn) {
      const connections = Connections.load();
      const newConenctions = connections.map((c) =>
        c.id === conn.id ? conn : c
      );
      const store = new Store();
      store.set("connections", newConenctions);
    }

    static removeConnection(id) {
      const connections = Connections.load();
      const newConnections = connections.filter((c) => c.id !== id);
      const store = new Store();
      store.set("connections", newConnections);
    }
  },
};
