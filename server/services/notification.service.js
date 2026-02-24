import admin from "firebase-admin";
import User from "../models/User.model.js";
import Customer from "../models/Customer.model.js";

/**
 * Send push notification to a single FCM token.
 * @param {string} token
 * @param {string} title
 * @param {string} body
 * @param {Object} data
 */
export const sendToToken = async (token, title, body, data = {}) => {
  if (!token) return;

  const message = {
    token,
    notification: {
      title,
      body,
    },
    data: Object.fromEntries(
      Object.entries(data).map(([k, v]) => [k, String(v)])
    ),
  };

  try {
    const response = await admin.messaging().send(message);
    return response;
  } catch (error) {
    // If token invalid → remove it
    if (
      error.code === "messaging/registration-token-not-registered" ||
      error.code === "messaging/invalid-registration-token"
    ) {
      await User.updateMany({ fcmToken: token }, { $set: { fcmToken: null } });
      await Customer.updateMany(
        { fcmToken: token },
        { $set: { fcmToken: null } }
      );
    }

    throw error;
  }
};
