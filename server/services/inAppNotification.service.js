import Notification from "../models/Notification.model.js";
import User from "../models/User.model.js";
import Customer from "../models/Customer.model.js";
import { sendToToken } from "./notification.service.js";

export const sendNotification = async ({
  userId,
  customerId,
  title,
  message,
  data = {},
}) => {
  let user = null;
  let customer = null;

  if (userId) user = await User.findById(userId);
  if (customerId) customer = await Customer.findById(customerId);

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

  await Notification.create({
    ownerId: userId,
    customerId,
    type: "system",
    title,
    message,
    data,
    channel: "push",
  });

  return fcmResult;
};
