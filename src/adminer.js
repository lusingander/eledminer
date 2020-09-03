const request = require("request");
const Const = require("./const");

const loginAndGetConnectionInfo = (args) => {
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
};

const checkConnection = (conn) => {
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
};

module.exports = {
  loginAndGetConnectionInfo: loginAndGetConnectionInfo,
  checkConnection: checkConnection,
};
