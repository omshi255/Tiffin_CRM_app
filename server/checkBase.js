import config from "./server/config/index.js";
console.log("env base", process.env.TRUECALLER_BASE_URL);
console.log("config base", config.TRUECALLER_BASE_URL);
const BASE_URL =
  process.env.TRUECALLER_BASE_URL || "https://api4.truecaller.com/v1";
console.log("computed base", BASE_URL);
