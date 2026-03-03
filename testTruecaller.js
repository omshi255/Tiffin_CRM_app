import config from "./server/config/index.js";

(async () => {
  console.log("key", config.TRUECALLER_API_KEY);
  try {
    const base =
      process.env.TRUECALLER_BASE_URL || "https://api4.truecaller.com/v1";
    const url = `${base}/verify?token=foo`;
    console.log("calling", url);
    const res = await fetch(url, {
      headers: {
        Authorization: `Bearer ${config.TRUECALLER_API_KEY}`,
        "Content-Type": "application/json",
      },
    });
    console.log("status", res.status);
    console.log(await res.text());
  } catch (e) {
    console.error("fetch error", e);
  }
})();
