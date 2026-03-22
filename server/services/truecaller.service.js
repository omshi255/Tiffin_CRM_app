import config from "../config/index.js";

// Legacy verify API (Bearer API key + token query) — optional path when client sends a raw token only.
const LEGACY_VERIFY_BASE =
  process.env.TRUECALLER_BASE_URL || "https://api4.truecaller.com/v1";

// OAuth 2.0 (PKCE) — same hosts as Truecaller’s Flutter example app.
const DEFAULT_OAUTH_TOKEN_URL =
  process.env.TRUECALLER_OAUTH_TOKEN_URL ||
  "https://oauth-account-noneu.truecaller.com/v1/token";
const DEFAULT_OAUTH_USERINFO_URL =
  process.env.TRUECALLER_OAUTH_USERINFO_URL ||
  "https://oauth-account-noneu.truecaller.com/v1/userinfo";

/**
 * Legacy: verify a token via Truecaller’s older verify endpoint (requires TRUECALLER_API_KEY).
 * @param {string} tcToken
 */
export const verifyToken = async (tcToken) => {
  if (!tcToken) {
    throw new Error("Truecaller token missing");
  }

  if (
    process.env.TRUECALLER_MOCK === "true" &&
    config.NODE_ENV !== "production"
  ) {
    return {
      phoneNumber: "+91" + String(tcToken).replace(/\D/g, "").slice(0, 10).padEnd(10, "0"),
      firstName: "Test",
      lastName: "User",
      truecallerId: `mock-${Date.now()}`,
    };
  }

  if (!config.TRUECALLER_API_KEY) {
    throw new Error("TRUECALLER_API_KEY is not configured");
  }

  const url = `${LEGACY_VERIFY_BASE}/verify?token=${encodeURIComponent(tcToken)}`;
  let res;
  try {
    res = await fetch(url, {
      headers: {
        Authorization: `Bearer ${config.TRUECALLER_API_KEY}`,
        "Content-Type": "application/json",
      },
    });
  } catch (err) {
    err.message = `network error calling Truecaller API (${err.message})`;
    throw err;
  }

  if (!res.ok) {
    const body = await res.text();
    throw new Error(`Truecaller verify failed (${res.status}): ${body}`);
  }

  return res.json();
};

/**
 * Normalize OpenID userinfo JSON to the shape used by auth.controller.
 * @param {Record<string, unknown>} data
 */
function normalizeUserInfoProfile(data) {
  const raw = data.phone_number || data.phoneNumber || "";
  const digits = String(raw).replace(/\D/g, "");
  const last10 = digits.length >= 10 ? digits.slice(-10) : digits;
  const phoneNumber =
    last10.length >= 10 ? `+91${last10}` : "";

  const name = data.name ? String(data.name) : "";
  const given = data.given_name ? String(data.given_name) : "";
  const family = data.family_name ? String(data.family_name) : "";
  const firstName =
    given || (name ? name.split(/\s+/)[0] : "") || "";
  const lastName =
    family ||
    (name && name.split(/\s+/).length > 1
      ? name.split(/\s+/).slice(1).join(" ")
      : "");

  return {
    phoneNumber,
    firstName,
    lastName,
    name,
    truecallerId: String(data.sub || data.id || ""),
  };
}

/**
 * Flutter Truecaller SDK (OAuth PKCE): exchange authorization code + code_verifier for access token,
 * then fetch OpenID userinfo. Matches official example:
 * POST https://oauth-account-noneu.truecaller.com/v1/token (form-urlencoded)
 * GET https://oauth-account-noneu.truecaller.com/v1/userinfo (Bearer)
 *
 * Requires TRUECALLER_CLIENT_ID (same value as Android manifest meta-data ClientId).
 *
 * @param {{ authorizationCode: string, codeVerifier: string }} params
 * @returns {Promise<Object>} profile compatible with auth.controller
 */
export const verifyOAuthPkce = async ({ authorizationCode, codeVerifier }) => {
  if (!authorizationCode || !codeVerifier) {
    throw new Error("authorization code and code_verifier are required");
  }

  if (
    process.env.TRUECALLER_MOCK === "true" &&
    config.NODE_ENV !== "production"
  ) {
    const digits = String(authorizationCode).replace(/\D/g, "").slice(0, 10);
    const ten = (digits + "0000000000").slice(0, 10);
    return {
      phoneNumber: `+91${ten}`,
      firstName: "Test",
      lastName: "User",
      truecallerId: `mock-${Date.now()}`,
    };
  }

  const clientId = config.TRUECALLER_CLIENT_ID;
  if (!clientId) {
    throw new Error(
      "TRUECALLER_CLIENT_ID is not configured (use the same OAuth Client Id as in AndroidManifest)"
    );
  }

  const tokenUrl = config.TRUECALLER_OAUTH_TOKEN_URL || DEFAULT_OAUTH_TOKEN_URL;
  const body = new URLSearchParams({
    grant_type: "authorization_code",
    client_id: clientId,
    code: authorizationCode,
    code_verifier: codeVerifier,
  });

  let tokenRes;
  try {
    tokenRes = await fetch(tokenUrl, {
      method: "POST",
      headers: {
        "Content-Type": "application/x-www-form-urlencoded",
        Accept: "application/json",
      },
      body: body.toString(),
    });
  } catch (err) {
    err.message = `network error calling Truecaller OAuth (${err.message})`;
    throw err;
  }

  if (!tokenRes.ok) {
    const errText = await tokenRes.text();
    throw new Error(
      `Truecaller token exchange failed (${tokenRes.status}): ${errText}`
    );
  }

  /** @type {{ access_token?: string }} */
  const tokens = await tokenRes.json();
  const accessToken = tokens.access_token;
  if (!accessToken) {
    throw new Error("Truecaller token response missing access_token");
  }

  const userinfoUrl =
    config.TRUECALLER_OAUTH_USERINFO_URL || DEFAULT_OAUTH_USERINFO_URL;
  let userRes;
  try {
    userRes = await fetch(userinfoUrl, {
      headers: {
        Authorization: `Bearer ${accessToken}`,
        Accept: "application/json",
      },
    });
  } catch (err) {
    err.message = `network error calling Truecaller userinfo (${err.message})`;
    throw err;
  }

  if (!userRes.ok) {
    const errText = await userRes.text();
    throw new Error(
      `Truecaller userinfo failed (${userRes.status}): ${errText}`
    );
  }

  const userJson = await userRes.json();
  return normalizeUserInfoProfile(userJson);
};
