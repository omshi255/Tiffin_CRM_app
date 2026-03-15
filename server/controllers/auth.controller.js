import Joi from "joi";
import User from "../models/User.model.js";
import DeliveryStaff from "../models/DeliveryStaff.model.js";
import config from "../config/index.js";
import { sendOtp, verifyOtp } from "../services/otp.service.js";
import * as passwordService from "../services/password.service.js";
import * as securePassword from "../services/securePassword.service.js";
import * as truecallerService from "../services/truecaller.service.js";
import * as emailService from "../services/email.service.js";
import {
  generateAccessToken,
  generateRefreshToken,
  verifyRefreshToken,
} from "../services/token.service.js";
import {
  resolveRoleForPhone,
  hasVendorBusinessData,
} from "../services/authRole.service.js";
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

// simple password strength: min 8, one lower, one upper, one digit
const passwordPattern = /^(?=.*[a-z])(?=.*[A-Z])(?=.*\d).{8,}$/;
const passwordMessage =
  "Password must be at least 8 characters and include upper, lower and number";

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

// ---------------- password management ----------------
const forgotPasswordSchema = Joi.object({
  phone: phoneSchema,
});

const resetPasswordSchema = Joi.object({
  token: Joi.string().required(),
  newPassword: Joi.string().pattern(passwordPattern).required().messages({
    "string.pattern.base": passwordMessage,
  }),
});

const truecallerSchema = Joi.object({
  accessToken: Joi.string().required(),
  // profile may be supplied by client to avoid extra API call;
  // if present we still verify the token for security, but it
  // allows UI code to pass along name/phone it already received.
  profile: Joi.object({
    phone: Joi.string().optional(),
    name: Joi.string().optional(),
    truecallerId: Joi.string().optional(),
  }).optional(),
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

  if (!result.success) {
    throw new ApiError(502, result.message || "Failed to send OTP");
  }

  const response = new ApiResponse(200, "OTP sent successfully");
  res.status(response.statusCode).json({
    success: response.success,
    message: response.message,
  });
});

// -----------------------------------------------------------------------------
// Password reset flow (Day 1)
// -----------------------------------------------------------------------------

/**
 * POST /api/v1/auth/forgot-password
 * Body: { phone: "9876543210" }
 */
export const forgotPasswordController = asyncHandler(async (req, res, next) => {
  // make sure body is an object so Joi doesn't quietly return undefined
  const { error, value } = forgotPasswordSchema.validate(req.body || {}, {
    stripUnknown: true,
    abortEarly: false,
  });

  if (error || !value || typeof value.phone === "undefined") {
    const msg = error
      ? error.details.map((d) => d.message).join("; ")
      : "phone is required";
    throw new ApiError(400, msg);
  }

  const { phone } = value;
  const user = await User.findOne({ phone }).lean();

  // always return 200 to avoid enumerating users
  const response = new ApiResponse(
    200,
    "If the phone is registered, a reset link has been sent"
  );

  // in development we return the raw token for easier testing
  const payload = {
    success: response.success,
    message: response.message,
  };

  let token;
  if (user) {
    // generate/reset token now so we can use it in email or debug output
    token = await passwordService.generateResetToken(user._id);
    if (config.NODE_ENV !== "production") {
      payload.debugToken = token;
      console.log("[forgot-password] token for", phone, token);
    }
  }

  res.status(response.statusCode).json(payload);

  if (!user) return;

  // send email if we know the address and user has enabled notifications
  if (user.email) {
    const resetLink =
      (config.FRONTEND_URL || "https://app.tiffincrm.com") + `/reset/${token}`;

    const emailResult = await emailService.sendEmail({
      to: user.email,
      subject: "Password Reset - TiffinCRM",
      template: "password-reset",
      data: {
        name: user.ownerName || user.name || "",
        resetLink,
        expiresIn: "10 minutes",
      },
    });

    if (!emailResult.success) {
      // log and continue; we don't want to reveal failure to the caller
      console.log("[forgot-password] failed to send email", emailResult.error);
    }
  } else {
    console.log("[forgot-password] no email on user", user._id);
  }
});

/**
 * POST /api/v1/auth/reset-password
 * Body: { token, newPassword }
 */
export const resetPasswordController = asyncHandler(async (req, res, next) => {
  const { error, value } = resetPasswordSchema.validate(req.body || {}, {
    stripUnknown: true,
    abortEarly: false,
  });

  if (
    error ||
    !value ||
    typeof value.token === "undefined" ||
    typeof value.newPassword === "undefined"
  ) {
    const msg = error
      ? error.details.map((d) => d.message).join("; ")
      : "token and newPassword are required";
    throw new ApiError(400, msg);
  }

  const { token, newPassword } = value;
  const user = await passwordService.resetPassword(token, newPassword);

  // Admin is never overridden
  let resolved;
  if (user.role === "admin") {
    resolved = { role: "admin", ownerId: null, staffId: null, customerId: null };
  } else if (user.role === "vendor") {
    resolved = { role: "vendor", ownerId: null, staffId: null, customerId: null };
  } else {
    resolved = await resolveRoleForPhone(user.phone);
  }
  const role = resolved.role;
  const ownerId =
    role === "admin"
      ? null
      : role === "vendor"
        ? user._id.toString()
        : resolved.ownerId || null;
  const staffId = resolved.staffId || null;
  const customerId = resolved.customerId || null;

  const payload = {
    userId: user._id.toString(),
    phone: user.phone,
    role,
    ...(ownerId && { ownerId }),
    ...(staffId && { staffId }),
    ...(customerId && { customerId }),
  };

  const accessToken = generateAccessToken(payload);
  const refreshToken = generateRefreshToken(payload);

  const resp = new ApiResponse(200, "Password updated", {
    accessToken,
    refreshToken,
    user: {
      id: user._id.toString(),
      phone: user.phone,
      name: user.name || "",
      role,
      ...(staffId && { staffId }),
      ...(customerId && { customerId }),
    },
  });

  res.status(resp.statusCode).json({
    success: resp.success,
    message: resp.message,
    data: resp.data,
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

  const resolved = await resolveRoleForPhone(phone);
  let user = await User.findOne({ phone });

  if (!user) {
    user = await User.create({ phone, role: resolved.role });
  } else if (user.role === "admin") {
    // Admin is never overridden: resolveRoleForPhone is not used for role/ownerId
  } else if (user.role === "vendor") {
    // Override to customer/delivery_staff ONLY if they have NO vendor business data.
    // Protects real vendors from abuse: a malicious vendor could add another vendor's
    // phone as customer to hijack their role. We only override "accidental vendors"
    // (empty account, no customers/plans/subscriptions).
    if (resolved.role !== "vendor") {
      const hasBusiness = await hasVendorBusinessData(user._id);
      if (!hasBusiness) {
        await User.updateOne(
          { _id: user._id },
          { $set: { role: resolved.role } }
        );
        user.role = resolved.role;
      } else {
        resolved.role = "vendor";
        resolved.ownerId = null;
      }
    } else {
      resolved.ownerId = null;
    }
  } else {
    // Keep customer/delivery_staff in sync: if resolved role changed, update user. Never overwrite admin.
    if (user.role !== resolved.role) {
      await User.updateOne(
        { _id: user._id },
        { $set: { role: resolved.role } }
      );
      user.role = resolved.role;
    }
  }

  // record login event
  user.loginHistory = user.loginHistory || [];
  user.loginHistory.push({
    ip: req.ip,
    userAgent: req.get("User-Agent") || "",
    at: new Date(),
  });
  await user.save();
  user = user.toObject();

  // Admin is never overridden: use stored user.role and no ownerId
  const role =
    user.role === "admin"
      ? "admin"
      : user.role === "vendor"
        ? "vendor"
        : resolved.role;
  const ownerId =
    role === "admin"
      ? null
      : role === "vendor"
        ? user._id.toString()
        : resolved.ownerId || null;

  // For delivery_staff: link their User account to DeliveryStaff if not already done
  let staffId = resolved.staffId || null;
  if (role === "delivery_staff" && staffId) {
    await DeliveryStaff.findByIdAndUpdate(staffId, {
      $set: { userId: user._id },
    });
  }

  const customerId = resolved.customerId || null;

  const payload = {
    userId: user._id.toString(),
    phone: user.phone,
    role,
    ...(ownerId && { ownerId }),
    ...(staffId && { staffId }),
    ...(customerId && { customerId }),
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
      ...(staffId && { staffId }),
      ...(customerId && { customerId }),
    },
  });

  res.status(response.statusCode).json({
    success: response.success,
    message: response.message,
    data: response.data,
  });
});

/**
 * POST /api/v1/auth/truecaller
 * Body: { accessToken }
 * Clients obtain `accessToken` from Truecaller SDK on the device.
 */
export const truecallerController = asyncHandler(async (req, res, next) => {
  const { error, value } = truecallerSchema.validate(req.body || {}, {
    stripUnknown: true,
    abortEarly: false,
  });

  if (error || !value || !value.accessToken) {
    const msg = error
      ? error.details.map((d) => d.message).join("; ")
      : "accessToken is required";
    throw new ApiError(400, msg);
  }

  const { accessToken, profile: clientProfile } = value;
  let profile = clientProfile || null;

  // always verify token to ensure it's valid and coming from Truecaller
  try {
    const remoteProfile = await truecallerService.verifyToken(accessToken);
    // use remote profile as authoritative, but if client provided name/phone
    // we can merge basic fields to reduce churn
    profile = { ...remoteProfile, ...profile };
  } catch (err) {
    const msg = err.message || "unknown error";
    // if network problem, propagate as 503 so client may retry later
    if (msg.includes("network error")) {
      throw new ApiError(503, `Truecaller service unavailable: ${msg}`);
    }
    throw new ApiError(401, `Truecaller verification failed: ${msg}`);
  }

  // profile object typically contains phoneNumber and name fields
  const phoneRaw = profile.phoneNumber || profile.phone || "";
  const phone = String(phoneRaw).replace(/^\+91/, "").trim();
  const tcId = profile.truecallerId || profile.id || "";

  const resolved = await resolveRoleForPhone(phone);

  // prefer matching by Truecaller ID if available
  let user = null;
  if (tcId) {
    user = await User.findOne({ truecallerId: tcId }).lean();
  }
  if (!user) {
    user = await User.findOne({ phone }).lean();
  }

  if (!user) {
    user = await User.create({
      phone,
      role: resolved.role,
      name:
        (profile.firstName || profile.name || "") +
        (profile.lastName ? " " + profile.lastName : ""),
      truecallerId: tcId,
    });
    user = user.toObject();
  } else {
    // Admin is never overridden
    if (user.role === "admin") {
      // keep role as admin; resolved is ignored for role/ownerId below
    } else if (user.role === "vendor" && resolved.role !== "vendor") {
      const hasBusiness = await hasVendorBusinessData(user._id);
      if (!hasBusiness) {
        await User.updateOne(
          { _id: user._id },
          { $set: { role: resolved.role } }
        );
        user.role = resolved.role;
      } else {
        resolved.role = "vendor";
        resolved.ownerId = null;
      }
    } else if (user.role === "vendor" && resolved.role === "vendor") {
      resolved.ownerId = null;
    } else if (user.role !== resolved.role) {
      await User.updateOne(
        { _id: user._id },
        { $set: { role: resolved.role } }
      );
      user.role = resolved.role;
    }
    // sync any missing fields
    const update = {};
    if (tcId && !user.truecallerId) update.truecallerId = tcId;
    if (phone && user.phone !== phone) update.phone = phone;
    if (Object.keys(update).length) {
      user = await User.findByIdAndUpdate(
        user._id,
        { $set: update },
        { new: true }
      ).lean();
    }
  }

  // Admin is never overridden
  const role =
    user.role === "admin"
      ? "admin"
      : user.role === "vendor"
        ? "vendor"
        : resolved.role;
  const ownerId =
    role === "admin"
      ? null
      : role === "vendor"
        ? user._id.toString()
        : resolved.ownerId || null;
  const tcCustomerId = resolved.customerId || null;
  const tcStaffId = resolved.staffId || null;

  // Link the User account back to the DeliveryStaff record on first Truecaller login.
  if (role === "delivery_staff" && tcStaffId) {
    await DeliveryStaff.findByIdAndUpdate(tcStaffId, {
      $set: { userId: user._id },
    });
  }

  const payload = {
    userId: user._id.toString(),
    phone: user.phone,
    role,
    ...(ownerId && { ownerId }),
    ...(tcStaffId && { staffId: tcStaffId }),
    ...(tcCustomerId && { customerId: tcCustomerId }),
  };
  const access = generateAccessToken(payload);
  const refresh = generateRefreshToken(payload);

  const response = new ApiResponse(200, "Login successful", {
    accessToken: access,
    refreshToken: refresh,
    user: {
      id: user._id.toString(),
      phone: user.phone,
      name: user.name || "",
      role,
      ...(tcStaffId && { staffId: tcStaffId }),
      ...(tcCustomerId && { customerId: tcCustomerId }),
    },
  });

  res.status(response.statusCode).json(response);
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

  // Admin is never overridden; vendor uses stored role; others use resolveRoleForPhone
  let resolved;
  if (user.role === "admin") {
    resolved = { role: "admin", ownerId: null, staffId: null, customerId: null };
  } else if (user.role === "vendor") {
    resolved = { role: "vendor", ownerId: null, staffId: null, customerId: null };
  } else {
    resolved = await resolveRoleForPhone(user.phone);
  }
  const role = resolved.role;
  const ownerId =
    role === "admin"
      ? null
      : role === "vendor"
        ? user._id.toString()
        : resolved.ownerId || null;
  const staffId = resolved.staffId || null;
  const customerId = resolved.customerId || null;

  const payload = {
    userId: user._id.toString(),
    phone: user.phone,
    role,
    ...(ownerId && { ownerId }),
    ...(staffId && { staffId }),
    ...(customerId && { customerId }),
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
      role,
      ...(staffId && { staffId }),
      ...(customerId && { customerId }),
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
 * GET /api/v1/auth/me
 * Returns profile of authenticated user
 */
export const getMeController = asyncHandler(async (req, res, next) => {
  const user = await User.findById(req.user.userId).lean();
  if (!user) throw new ApiError(404, "User not found");

  const response = new ApiResponse(200, "User profile", {
    id: user._id.toString(),
    phone: user.phone,
    name: user.name || "",
    role: user.role,
    email: user.email,
    businessName: user.businessName,
    ownerName: user.ownerName,
    city: user.city,
    settings: user.settings,
    loginHistory: user.loginHistory || [],
  });

  res.status(response.statusCode).json(response);
});

/**
 * PUT /api/v1/auth/change-password
 * Body: { currentPassword, newPassword }
 */
export const changePasswordController = asyncHandler(async (req, res, next) => {
  const schema = Joi.object({
    currentPassword: Joi.string().min(8).required(),
    newPassword: Joi.string().pattern(passwordPattern).required().messages({
      "string.pattern.base": passwordMessage,
    }),
  });

  const { error, value } = schema.validate(req.body || {}, {
    stripUnknown: true,
    abortEarly: false,
  });
  if (
    error ||
    !value ||
    typeof value.currentPassword === "undefined" ||
    typeof value.newPassword === "undefined"
  ) {
    const msg = error
      ? error.details.map((d) => d.message).join("; ")
      : "currentPassword and newPassword are required";
    throw new ApiError(400, msg);
  }

  const user = await User.findById(req.user.userId);
  if (!user) throw new ApiError(404, "User not found");

  if (!user.passwordHash) {
    // no password set yet.
    throw new ApiError(400, "No password exists for this account");
  }

  const isValid = await securePassword.validatePassword(
    value.currentPassword,
    user.passwordHash
  );
  if (!isValid) throw new ApiError(401, "Current password incorrect");

  user.passwordHash = await securePassword.hashPassword(value.newPassword);
  await user.save();

  res
    .status(200)
    .json(new ApiResponse(200, "Password changed, please login again"));
});

/**
 * PUT /api/v1/auth/me
 * Update logged-in user's profile (fcmToken, businessName, ownerName, city, etc.)
 */
export const updateMe = asyncHandler(async (req, res) => {
  const schema = Joi.object({
    fcmToken: Joi.string().optional(),
    businessName: Joi.string().trim().optional(),
    ownerName: Joi.string().trim().optional(),
    city: Joi.string().trim().optional(),
    address: Joi.string().trim().optional(),
    email: Joi.string().email().optional(),
    logoUrl: Joi.string().uri().optional(),
  }).min(1);

  const { error, value } = schema.validate(req.body, {
    stripUnknown: true,
    abortEarly: false,
  });
  if (error) {
    throw new ApiError(400, error.details.map((d) => d.message).join("; "));
  }

  const updatePayload = { ...value };

  const user = await User.findByIdAndUpdate(
    req.user.userId,
    { $set: updatePayload },
    { new: true }
  ).lean();

  const response = new ApiResponse(200, "Profile updated", {
    user: {
      id: user._id,
      phone: user.phone,
      businessName: user.businessName,
      ownerName: user.ownerName,
      city: user.city,
      fcmToken: user.fcmToken,
    },
  });

  res.status(response.statusCode).json(response);
});
