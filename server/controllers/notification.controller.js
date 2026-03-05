import { sendToToken } from "../services/notification.service.js";
import { asyncHandler } from "../utils/asyncHandler.js";
import { ApiResponse } from "../class/apiResponseClass.js";
import { ApiError } from "../class/apiErrorClass.js";
import User from "../models/User.model.js";
import { sendNotification } from "../services/inAppNotification.service.js";

export const testNotification = async (req, res) => {
  const { customerId } = req.body;

  const result = await sendNotification({
    customerId,
    title: "Test notification",
    message: "This is a test push notification",
  });

  res.json({
    success: true,
    result,
  });
};
