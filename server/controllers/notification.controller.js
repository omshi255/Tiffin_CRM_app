import { sendToToken } from "../services/notification.service.js";
import { asyncHandler } from "../utils/asyncHandler.js";
import { ApiResponse } from "../class/apiResponseClass.js";
import { ApiError } from "../class/apiErrorClass.js";
import User from "../models/User.model.js";

export const testNotification = asyncHandler(async (req, res) => {
  const user = await User.findById(req.user.userId);

  if (!user?.fcmToken) {
    throw new ApiError(400, "User does not have FCM token saved");
  }

  await sendToToken(
    user.fcmToken,
    "Test Notification 🚀",
    "Your FCM integration is working!",
    { type: "test" }
  );

  const response = new ApiResponse(200, "Notification sent");
  res.status(response.statusCode).json(response);
});
