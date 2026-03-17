import Joi from "joi";
import { asyncHandler } from "../utils/asyncHandler.js";
import { ApiResponse } from "../class/apiResponseClass.js";
import { ApiError } from "../class/apiErrorClass.js";
import Notification from "../models/Notification.model.js";
import { sendNotification } from "../services/inAppNotification.service.js";
import { NOTIFICATION_TYPES } from "../utils/notificationTypes.js";

const VALID_TYPES = Object.values(NOTIFICATION_TYPES);

const listQuerySchema = Joi.object({
  page: Joi.number().integer().min(1).optional(),
  limit: Joi.number().integer().min(1).max(50).optional(),
  isRead: Joi.boolean().truthy("true").falsy("false").optional(),
});

/**
 * GET /api/v1/notifications
 * List notifications for current user (vendor/delivery by ownerId, admin sees all).
 */
export const listMyNotifications = asyncHandler(async (req, res) => {
  const { error, value } = listQuerySchema.validate(req.query, {
    stripUnknown: true,
    abortEarly: false,
  });
  if (error) {
    throw new ApiError(400, error.details.map((d) => d.message).join("; "));
  }

  const page = value.page || 1;
  const limit = value.limit || 20;
  const skip = (page - 1) * limit;

  const filter = {};
  if (req.user.role === "admin") {
    // Admin sees all (no owner filter)
  } else {
    filter.ownerId = req.user.userId;
  }
  if (typeof value.isRead === "boolean") filter.isRead = value.isRead;

  const [data, total] = await Promise.all([
    Notification.find(filter)
      .select("type title message data isRead sentAt createdAt")
      .sort({ sentAt: -1 })
      .skip(skip)
      .limit(limit)
      .lean(),
    Notification.countDocuments(filter),
  ]);

  res.status(200).json(
    new ApiResponse(200, "Notifications fetched", {
      data,
      total,
      page,
      limit,
      totalPages: Math.ceil(total / limit),
    })
  );
});

/**
 * PATCH /api/v1/notifications/:id/read
 * Mark a notification as read. Must belong to current user (ownerId or admin).
 */
export const markNotificationRead = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const filter = { _id: id };
  if (req.user.role !== "admin") {
    filter.ownerId = req.user.userId;
  }

  const updated = await Notification.findOneAndUpdate(
    filter,
    { $set: { isRead: true } },
    { new: true }
  )
    .select("_id type title message isRead sentAt")
    .lean();

  if (!updated) throw new ApiError(404, "Notification not found");

  res.status(200).json(new ApiResponse(200, "Marked as read", updated));
});

/**
 * POST /api/v1/notifications/test
 * Body: { customerId, type? }
 * Only vendor/admin can send test.
 */
export const testNotification = asyncHandler(async (req, res) => {
  if (req.user.role === "delivery_staff") {
    throw new ApiError(403, "Delivery staff cannot send test notifications");
  }

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
