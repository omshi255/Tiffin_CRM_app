import User from "../models/User.model.js";
import Customer from "../models/Customer.model.js";
import { sendPushNotification } from "./fcm.service.js";

/**
 * Send push notification to a single FCM token (invalid tokens are cleared).
 * @param {string} token
 * @param {string} title
 * @param {string} body
 * @param {Object} data
 */
export const sendToToken = async (token, title, body, data = {}) => {
  if (!token) return;

  try {
    const response = await sendPushNotification(token, title, body, data);
    return response;
  } catch (error) {
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
