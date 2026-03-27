import admin from "../config/firebase.js";

const ANDROID_CHANNEL_ID = "tiffin_crm_channel";

/**
 * Send a data + notification message to one device (Firebase Admin SDK).
 * @param {string} fcmToken
 * @param {string} title
 * @param {string} body
 * @param {Record<string, string|number|boolean|undefined|null>} [data]
 */
export const sendPushNotification = async (fcmToken, title, body, data = {}) => {
  if (!fcmToken) return null;

  const stringData = Object.fromEntries(
    Object.entries(data || {})
      .filter(([, v]) => v !== undefined && v !== null)
      .map(([k, v]) => [k, String(v)])
  );

  const message = {
    token: fcmToken,
    notification: { title, body },
    data: stringData,
    android: {
      priority: "high",
      notification: {
        channelId: ANDROID_CHANNEL_ID,
        sound: "default",
      },
    },
  };

  return admin.messaging().send(message);
};
