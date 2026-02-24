import Joi from "joi";
import User from "../models/User.model.js";
import { sendOtp, verifyOtp } from "../services/otp.service.js";
import {
  generateAccessToken,
  generateRefreshToken,
  verifyRefreshToken,
} from "../services/token.service.js";
import { asyncHandler } from "../utils/asyncHandler.js";
import { ApiResponse } from "../class/apiResponseClass.js";
import { ApiError } from "../class/apiErrorClass.js";

const phoneSchema = Joi.string()
  .pattern(/^[6-9]\d{9}$/)
  .required()
  .messages({
    "string.pattern.base":
      "Phone must be a valid 10-digit Indian mobile number",
  });

const sendOtpSchema = Joi.object({
  phone: phoneSchema,
});

const verifyOtpSchema = Joi.object({
  phone: phoneSchema,
  otp: Joi.string().length(6).pattern(/^\d+$/).required().messages({
    "string.length": "OTP must be 6 digits",
    "string.pattern.base": "OTP must contain only digits",
  }),
});

const refreshTokenSchema = Joi.object({
  refreshToken: Joi.string().required(),
});

/**
 * POST /api/v1/auth/send-otp
 * Body: { phone: "9876543210" }
 */
export const sendOtpController = asyncHandler(async (req, res, next) => {
  const { error, value } = sendOtpSchema.validate(req.body, {
    stripUnknown: true,
    abortEarly: false,
  });

  if (error) {
    throw new ApiError(400, error.details.map((d) => d.message).join("; "));
  }

  const { phone } = value;
  const result = await sendOtp(phone);
  console.log(result, " cheaking the result");

  if (!result.success) {
    throw new ApiError(502, result.message || "Failed to send OTP");
  }

  const response = new ApiResponse(200, "OTP sent successfully");
  res.status(response.statusCode).json({
    success: response.success,
    message: response.message,
  });
});

/**
 * POST /api/v1/auth/verify-otp
 * Body: { phone: "9876543210", otp: "123456" }
 * Returns: { accessToken, refreshToken, user }
 */
export const verifyOtpController = asyncHandler(async (req, res, next) => {
  const { error, value } = verifyOtpSchema.validate(req.body, {
    stripUnknown: true,
    abortEarly: false,
  });

  if (error) {
    throw new ApiError(400, error.details.map((d) => d.message).join("; "));
  }

  const { phone, otp } = value;
  const isValid = await verifyOtp(phone, otp);

  if (!isValid) {
    throw new ApiError(401, "Invalid or expired OTP");
  }

  let user = await User.findOne({ phone }).lean();

  if (!user) {
    user = await User.create({ phone });
    user = user.toObject();
  }

  const payload = {
    userId: user._id.toString(),
    phone: user.phone,
  };

  const accessToken = generateAccessToken(payload);
  const refreshToken = generateRefreshToken(payload);

  const response = new ApiResponse(200, "Login successful", {
    accessToken,
    refreshToken,
    user: {
      id: user._id.toString(),
      phone: user.phone,
      name: user.name || "",
      role: user.role,
    },
  });

  res.status(response.statusCode).json({
    success: response.success,
    message: response.message,
    data: response.data,
  });
});

/**
 * POST /api/v1/auth/refresh-token
 * Body: { refreshToken: "..." }
 */
export const refreshTokenController = asyncHandler(async (req, res, next) => {
  const { error, value } = refreshTokenSchema.validate(req.body, {
    stripUnknown: true,
    abortEarly: false,
  });

  if (error) {
    throw new ApiError(400, error.details.map((d) => d.message).join("; "));
  }

  const { refreshToken } = value;

  let decoded;
  try {
    decoded = verifyRefreshToken(refreshToken);
  } catch (err) {
    throw new ApiError(401, "Invalid or expired refresh token");
  }

  const user = await User.findById(decoded.userId).lean();
  if (!user) {
    throw new ApiError(401, "User not found");
  }

  const payload = {
    userId: user._id.toString(),
    phone: user.phone,
  };

  const newAccessToken = generateAccessToken(payload);
  const newRefreshToken = generateRefreshToken(payload);

  const response = new ApiResponse(200, "Tokens refreshed", {
    accessToken: newAccessToken,
    refreshToken: newRefreshToken,
    user: {
      id: user._id.toString(),
      phone: user.phone,
      name: user.name || "",
      role: user.role,
    },
  });

  res.status(response.statusCode).json({
    success: response.success,
    message: response.message,
    data: response.data,
  });
});

/**
 * POST /api/v1/auth/logout
 * Optional: client discards tokens; no server-side invalidation for now.
 */
export const logoutController = asyncHandler(async (req, res, next) => {
  const response = new ApiResponse(200, "Logged out successfully");
  res.status(response.statusCode).json({
    success: response.success,
    message: response.message,
  });
});

/**
 * PUT /api/v1/auth/me
 * Save FCM token for logged-in user
 */
export const updateMe = asyncHandler(async (req, res) => {
  const { fcmToken } = req.body;

  if (!fcmToken) {
    throw new ApiError(400, "fcmToken is required");
  }

  const user = await User.findByIdAndUpdate(
    req.user.userId,
    { $set: { fcmToken } },
    { new: true }
  ).lean();

  const response = new ApiResponse(200, "FCM token saved", {
    user: {
      id: user._id,
      phone: user.phone,
      fcmToken: user.fcmToken,
    },
  });

  res.status(response.statusCode).json(response);
});
