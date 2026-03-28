import admin from "../config/firebase.js";

const ANDROID_CHANNEL_ID = "tiffin_crm_channel";

/**
 * Send a data + notification message to one device (Firebase Admin SDK).
 * @param {string} token
 * @param {string} title
 * @param {string} body
 * @param {Record<string, unknown>} [data]
 */
export const sendPushNotification = async (token, title, body, data = {}) => {
  if (!token) {
    console.warn("[FCM DEBUG] sendPushNotification: empty token — skipping send");
    return null;
  }

  const stringData = Object.fromEntries(
    Object.entries(data || {}).map(([k, v]) => [
      k,
      v == null ? "" : String(v),
    ])
  );

  const message = {
    notification: { title, body },
    data: stringData,
    android: {
      priority: "high",
      notification: {
        channelId: ANDROID_CHANNEL_ID,
        priority: "high",
        defaultSound: true,
        defaultVibrateTimings: true,
      },
    },
    apns: {
      payload: {
        aps: {
          alert: { title, body },
          sound: "default",
          badge: 1,
          contentAvailable: true,
        },
      },
      headers: { "apns-priority": "10" },
    },
    token,
  };

  console.log(
    "[FCM DEBUG] Sending to token:",
    `${token.substring(0, 20)}...`
  );
  console.log("[FCM DEBUG] Payload:", JSON.stringify(message, null, 2));

  const response = await admin.messaging().send(message);
  console.log("[FCM DEBUG] FCM response:", response);
  return response;
};
