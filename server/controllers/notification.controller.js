import { asyncHandler } from "../utils/asyncHandler.js";
import { ApiResponse } from "../class/apiResponseClass.js";
import { ApiError } from "../class/apiErrorClass.js";
import { sendNotification } from "../services/inAppNotification.service.js";
import { NOTIFICATION_TYPES } from "../utils/notificationTypes.js";

const VALID_TYPES = Object.values(NOTIFICATION_TYPES);

/**
 * POST /api/v1/notifications/test
 * Body: { customerId, type? }
 */
export const testNotification = asyncHandler(async (req, res) => {
  const { customerId, type } = req.body;

  if (!customerId) {
    throw new ApiError(400, "customerId is required");
  }

  const notifType = VALID_TYPES.includes(type)
    ? type
    : NOTIFICATION_TYPES.ORDER_PROCESSING;

  const result = await sendNotification({
    customerId,
    ownerId: req.user.userId,
    type: notifType,
    title: "Test notification",
    message: "This is a test push notification",
    data: { screen: "home" },
  });

  res.status(200).json(
    new ApiResponse(200, "Test notification sent", {
      result,
      type: notifType,
      validTypes: VALID_TYPES,
    })
  );
});
