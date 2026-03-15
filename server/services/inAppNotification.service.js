import Notification from "../models/Notification.model.js";
import User from "../models/User.model.js";
import Customer from "../models/Customer.model.js";
import { sendToToken } from "./notification.service.js";

/**
 * Send a push notification + create a Notification document.
 *
 * @param {object} opts
 * @param {string} [opts.userId]     - Vendor/user ObjectId → fetch their FCM token
 * @param {string} [opts.customerId] - Customer ObjectId → fetch their FCM token
 * @param {string} [opts.ownerId]    - Explicit vendor ownerId for scoping the Notification doc
 *                                     (defaults to userId when not provided)
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
  let user = null;
  let customer = null;

  if (userId) user = await User.findById(userId).select("fcmToken").lean();
  if (customerId) customer = await Customer.findById(customerId).select("fcmToken").lean();

  const token = user?.fcmToken || customer?.fcmToken;
  let fcmResult = null;

  if (token) {
    try {
      await sendToToken(token, title, message, data);
      fcmResult = { success: true };
    } catch (err) {
      fcmResult = { success: false, error: err.message };
    }
  }

  // ownerId priority: explicit > userId (vendor sending to themselves) > undefined
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

  return fcmResult;
};
