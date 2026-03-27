import Joi from "joi";
import { asyncHandler } from "../utils/asyncHandler.js";
import { ApiError } from "../class/apiErrorClass.js";
import User from "../models/User.model.js";
import Customer from "../models/Customer.model.js";

/**
 * PUT /api/v1/users/fcm-token
 * Body: { fcmToken: string | null }
 */
export const updateFcmToken = asyncHandler(async (req, res) => {
  const schema = Joi.object({
    fcmToken: Joi.string().allow(null, "").optional(),
  });

  const { error, value } = schema.validate(req.body || {}, {
    stripUnknown: true,
    abortEarly: false,
  });
  if (error) {
    throw new ApiError(400, error.details.map((d) => d.message).join("; "));
  }

  const fcmToken = value.fcmToken ?? null;

  if (req.user.role === "customer" && req.user.customerId) {
    await Customer.findByIdAndUpdate(req.user.customerId, {
      $set: { fcmToken },
    });
  } else {
    await User.findByIdAndUpdate(req.user.userId, { $set: { fcmToken } });
  }

  res.status(200).json({ success: true });
});
