const execa = require("execa");

module.exports = {
  // ref: https://github.com/felixfbecker/vscode-php-intellisense/blob/master/src/extension.ts
  canExecutePHP: (php) => {
    try {
      const result = execa.sync(php, ["--version"]);
      const match = result.stdout.match(/^PHP 7/);
      return result.exitCode === 0 && !!match;
    } catch (e) {
      return false;
    }
  },
};
