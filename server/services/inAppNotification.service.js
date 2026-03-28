import Notification from "../models/Notification.model.js";
import { sendPushToUser } from "./onesignal.service.js";

/**
 * Send a push notification + create a Notification document.
 *
 * @param {object} opts
 * @param {string} [opts.userId]     - Vendor/user ObjectId → OneSignal external_id
 * @param {string} [opts.customerId] - Customer ObjectId → OneSignal external_id
 * @param {string} [opts.ownerId]    - Explicit vendor ownerId for scoping the Notification doc
 * @param {string} [opts.type]       - Notification type constant (from notificationTypes.js)
 * @param {string}  opts.title       - Notification title
 * @param {string}  opts.message     - Notification body
 * @param {object} [opts.data]       - Extra payload
 */
export const sendNotification = async ({
  userId,
  customerId,
  ownerId,
  type = "system",
  title,
  message,
  data = {},
}) => {
  const targetId = userId || customerId || null;

  console.log("[OneSignal] sendNotification", {
    targetId,
    type,
    title,
  });

  let pushResult = null;
  if (targetId) {
    try {
      pushResult = await sendPushToUser(String(targetId), title, message, {
        ...data,
        type: type || "system",
      });
    } catch (err) {
      console.error("[OneSignal] push failed:", err.message);
      pushResult = { success: false, error: err.message };
    }
  }

  const notifOwnerId = ownerId || userId || undefined;

  await Notification.create({
    ownerId: notifOwnerId,
    customerId,
    type,
    title,
    message,
    data,
    channel: "in_app",
  });
  console.log("[OneSignal] in-app Notification.create done", {
    type,
    notifOwnerId: notifOwnerId?.toString?.() ?? notifOwnerId,
    customerId: customerId?.toString?.() ?? customerId,
  });

  return pushResult;
};
