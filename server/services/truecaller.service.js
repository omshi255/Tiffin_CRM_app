import config from "../config/index.js";

// allow overriding the API host because the public docs have changed
// over time; the default may not resolve in your environment.
const BASE_URL =
  process.env.TRUECALLER_BASE_URL || "https://api4.truecaller.com/v1";

/**
 * Verify a Truecaller access token obtained from the mobile SDK.
 *
 * Developer notes:
 * - supply TRUECALLER_API_KEY in .env (required in production)
 * - if the DNS name above is invalid, set TRUECALLER_BASE_URL to the
 *   correct host from Truecaller’s docs (e.g. https://verify.truecaller.com/v1).
 * - for local testing you can set TRUECALLER_MOCK=true to bypass the call
 *   and get a fake profile back instead.
 *
 * @param {string} tcToken
 * @returns {Promise<Object>} parsed JSON from Truecaller
 * @throws when the key is missing or the request fails
 */
export const verifyToken = async (tcToken) => {
  if (!tcToken) {
    throw new Error("Truecaller token missing");
  }

  // mock mode for development / offline demos
  if (
    process.env.TRUECALLER_MOCK === "true" &&
    config.NODE_ENV !== "production"
  ) {
    // return a plausible object using the token as phone
    return {
      phoneNumber: "+91" + tcToken.slice(0, 10),
      firstName: "Test",
      lastName: "User",
      truecallerId: `mock-${Date.now()}`,
    };
  }

  if (!config.TRUECALLER_API_KEY) {
    throw new Error("TRUECALLER_API_KEY is not configured");
  }

  const url = `${BASE_URL}/verify?token=${encodeURIComponent(tcToken)}`;
  let res;
  try {
    res = await fetch(url, {
      headers: {
        Authorization: `Bearer ${config.TRUECALLER_API_KEY}`,
        "Content-Type": "application/json",
      },
    });
  } catch (err) {
    // network/ DNS error
    err.message = `network error calling Truecaller API (${err.message})`;
    throw err;
  }

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`Truecaller verify failed (${res.status}): ${body}`);
  }

  return res.json();
};
