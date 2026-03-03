import config from "./server/config/index.js";
config.TRUECALLER_MOCK = "true";
import * as svc from "./server/services/truecaller.service.js";

(async () => {
  try {
    const p = await svc.verifyToken("tokendummy123");
    console.log("mock profile", p);
  } catch (e) {
    console.error("error", e);
  }
})();
