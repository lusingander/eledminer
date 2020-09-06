const request = require("request");
const PHPServer = require("php-server-manager");
const path = require("path");
const Const = require("./const");
const { UserSettings } = require("./store");

module.exports = {
  newServer: () => {
    const userSettings = UserSettings.load();
    return new PHPServer({
      port: userSettings.port,
      directory: path.join(__dirname, ".."),
      directives: {
        display_errors: 1,
        expose_php: 1,
      },
      env: {
        ELEDMINER_SETTINGS_THEME: userSettings.theme,
      },
    });
  },

  loginAndGetConnectionInfo: (args) => {
    return new Promise((resolve, reject) => {
      const baseUrl = args.baseUrl;
      const driver = args.driver;
      const server = args.server;
      const username = args.username;
      const password = args.password;
      const filepath = args.filepath;

      let formData;
      if (driver === "sqlite" || driver === "sqlite2") {
        formData = {
          "auth[driver]": driver,
          "auth[username]": "",
          "auth[password]": Const.sqliteDummyPassword,
          "auth[db]": filepath,
        };
      } else {
        formData = {
          "auth[driver]": driver,
          "auth[server]": server,
          "auth[username]": username,
          "auth[password]": password,
        };
      }
      const options = { url: baseUrl, method: "POST", form: formData };

      request(options, (error, response, body) => {
        if (error) {
          return reject(error);
        }
        const statusCode = response["statusCode"];
        if (statusCode !== 302) {
          return reject();
        }
        const cookieStr = response["headers"]["set-cookie"][0];
        const location = response["headers"]["location"];
        const adminerSid = cookieStr.match("adminer_sid=([^¥S;]*)")[1];
        return resolve({
          redirectUrl: baseUrl + location,
          cookie: {
            url: baseUrl,
            name: "adminer_sid",
            value: adminerSid,
          },
        });
      });
    });
  },

  checkConnection: (conn) => {
    return new Promise((resolve, reject) => {
      const cookie = request.cookie(`${conn.cookie.name}=${conn.cookie.value}`);
      const headers = {
        Cookie: cookie,
      };
      const options = {
        url: conn.redirectUrl,
        method: "GET",
        headers: headers,
      };
      request(options, (error, response, body) => {
        if (error) {
          return reject(error);
        }
        const statusCode = response["statusCode"];
        if (statusCode !== 200) {
          return reject();
        }
        resolve(conn);
      });
    });
  },
};
