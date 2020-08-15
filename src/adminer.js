const request = require("request");

exports.loginAndGetConnectionInfo = (args) => {
  return new Promise((resolve, reject) => {
    const baseUrl = args.baseUrl;
    const server = args.server;
    const username = args.username;
    const password = args.password;

    const formData = {
      "auth[driver]": "server",
      "auth[server]": server,
      "auth[username]": username,
      "auth[password]": password,
    };
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
