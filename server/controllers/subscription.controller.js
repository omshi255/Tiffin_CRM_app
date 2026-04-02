import Joi from "joi";
import mongoose from "mongoose";
import Subscription, {
  SUBSCRIPTION_STATUSES,
} from "../models/Subscription.model.js";
import Customer from "../models/Customer.model.js";
import MealPlan from "../models/Plan.model.js";
import { asyncHandler } from "../utils/asyncHandler.js";
import { effectiveWallet } from "../utils/customerWallet.js";
import { ApiResponse } from "../class/apiResponseClass.js";
import { ApiError } from "../class/apiErrorClass.js";
import { generateDailyOrdersForDate } from "../services/dailyOrder.service.js";
import { sendNotification } from "../services/inAppNotification.service.js";
import { NOTIFICATION_TYPES } from "../utils/notificationTypes.js";
import { notifyIfWalletJustHitZero } from "../utils/walletZeroNotification.js";

const pauseSchema = Joi.object({
  pausedFrom: Joi.date().iso().required(),
  pausedUntil: Joi.date().iso().min(Joi.ref("pausedFrom")).required(),
});

const MAX_LIMIT = 100;
const DEFAULT_LIMIT = 20;
const DEFAULT_PAGE = 1;

function normalizeSubscriptionLedger(subscription) {
  if (!subscription || typeof subscription !== "object") return subscription;

  const total = Number(subscription.totalAmount ?? 0);
  const hasPositiveTotal = Number.isFinite(total) && total > 0;
  const paid = Number(subscription.paidAmount ?? 0);

  // Legacy safety: older rows may have paidAmount missing/0 while new flow
  // always prepays full subscription amount from wallet at create/renew time.
  if (hasPositiveTotal && paid <= 0) {
    subscription.paidAmount = total;
  }

  if (hasPositiveTotal && subscription.remainingBalance == null) {
    subscription.remainingBalance = total;
  }

  return subscription;
}

const createSubscriptionSchema = Joi.object({
  customerId: Joi.string().hex().length(24).required(),
  planId: Joi.string().hex().length(24).required(),
  startDate: Joi.date().iso().required(),
  endDate: Joi.date().iso().min(Joi.ref("startDate")).required(),
  deliverySlot: Joi.string()
    .valid("morning", "afternoon", "evening")
    .required(),
  deliveryDays: Joi.array().items(Joi.number().min(0).max(6)).min(1).required(),
  autoRenew: Joi.boolean().default(false),
  notes: Joi.string().allow("", null),
});

const renewSubscriptionSchema = Joi.object({
  startDate: Joi.date().iso().required(),
  endDate: Joi.date().iso().min(Joi.ref("startDate")).required(),
});

const listQuerySchema = Joi.object({
  page: Joi.number().integer().min(1).optional(),
  limit: Joi.number().integer().min(1).max(MAX_LIMIT).optional(),
  status: Joi.string()
    .valid(...SUBSCRIPTION_STATUSES)
    .optional(),
  customerId: Joi.string().hex().length(24).optional(),
});

/**
 * GET /api/v1/subscriptions
 * Query: page, limit, status, customerId
 */
export const listSubscriptions = asyncHandler(async (req, res) => {
  const { error, value } = listQuerySchema.validate(req.query, {
    stripUnknown: true,
    abortEarly: false,
  });
  if (error) {
    throw new ApiError(400, error.details.map((d) => d.message).join("; "));
  }

  const page = value.page || DEFAULT_PAGE;
  const limit = Math.min(value.limit || DEFAULT_LIMIT, MAX_LIMIT);
  const skip = (page - 1) * limit;

  const ownerId = req.user.userId;
  const filter = { ownerId };
  if (value.status) filter.status = value.status;
  if (value.customerId) filter.customerId = value.customerId;

  const [data, total] = await Promise.all([
    Subscription.find(filter)
      .populate("customerId", "name phone address")
      .populate("planId", "planName price planType")
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .lean(),
    Subscription.countDocuments(filter),
  ]);

  const normalizedData = data.map((subscription) =>
    normalizeSubscriptionLedger(subscription)
  );
  const totalPages = Math.ceil(total / limit);

  const response = new ApiResponse(200, "Subscriptions fetched", {
    data: normalizedData,
    total,
    page,
    limit,
    totalPages,
  });

  res.status(response.statusCode).json({
    success: response.success,
    message: response.message,
    data: response.data,
  });
});

/**
 * GET /api/v1/subscriptions/:id
 */
export const getSubscriptionById = asyncHandler(async (req, res) => {
  const ownerId = req.user.userId;
  const { id } = req.params;
  const subscription = await Subscription.findOne({ _id: id, ownerId })
    .populate("customerId", "name phone address")
    .populate("planId", "planName price planType")
    .lean();

  if (!subscription) {
    throw new ApiError(404, "Subscription not found");
  }

  const response = new ApiResponse(
    200,
    "Subscription fetched",
    normalizeSubscriptionLedger(subscription)
  );
  res.status(response.statusCode).json({
    success: response.success,
    message: response.message,
    data: response.data,
  });
});

/**
 * POST /api/v1/subscriptions
 */
export const createSubscription = asyncHandler(async (req, res) => {
  console.log("========== CREATE SUBSCRIPTION START ==========");

  const { error, value } = createSubscriptionSchema.validate(req.body, {
    stripUnknown: true,
    abortEarly: false,
  });

  if (error) {
    console.log("❌ Validation Error:", error.details);
    throw new ApiError(400, error.details.map((d) => d.message).join("; "));
  }

  // Convert ownerId safely
  const ownerId = new mongoose.Types.ObjectId(req.user.userId);

  // Validate ObjectIds
  if (!mongoose.Types.ObjectId.isValid(value.customerId)) {
    throw new ApiError(400, "Invalid customerId");
  }

  if (!mongoose.Types.ObjectId.isValid(value.planId)) {
    throw new ApiError(400, "Invalid planId");
  }

  const customerId = new mongoose.Types.ObjectId(value.customerId);
  const planId = new mongoose.Types.ObjectId(value.planId);

  console.log("🔍 ownerId:", ownerId.toString());
  console.log("🔍 customerId:", customerId.toString());
  console.log("🔍 planId:", planId.toString());

  const [customer, plan] = await Promise.all([
    Customer.findOne({
      _id: customerId,
      ownerId,
      isDeleted: { $ne: true },
    }),
    MealPlan.findOne({
      _id: planId,
      ownerId,
    }),
  ]);

  console.log("👤 Customer Found:", customer);
  console.log("📦 Plan Found:", plan);

  if (!customer) {
    console.log("❌ Customer not found");
    throw new ApiError(404, "Customer not found");
  }

  if (!plan) {
    console.log("❌ Plan not found");
    throw new ApiError(404, "Plan not found");
  }

  if (!plan.isActive) {
    console.log("❌ Plan is inactive");
    throw new ApiError(400, "Plan is not active");
  }

  // If this is a customer-specific plan, ensure it was created for THIS customer only.
  if (plan.customerId && plan.customerId.toString() !== customerId.toString()) {
    throw new ApiError(
      400,
      "This plan is a custom plan for a different customer and cannot be assigned here"
    );
  }

  const startDate = new Date(value.startDate);
  const endDate = new Date(value.endDate);

  const today = new Date();
  today.setHours(0, 0, 0, 0);

  if (startDate < today) {
    throw new ApiError(400, "Subscription start date cannot be in the past");
  }

  if (endDate < startDate) {
    throw new ApiError(400, "End date must be after start date");
  }

  const existingActive = await Subscription.findOne({
    ownerId,
    customerId,
    status: "active",
  });

  if (existingActive) {
    console.log("❌ Active subscription already exists");
    throw new ApiError(409, "Active subscription already exists for customer");
  }

  const totalDays =
    Math.floor(
      (endDate.getTime() - startDate.getTime()) / (1000 * 60 * 60 * 24)
    ) + 1;

  const totalAmount = plan.price * totalDays;

  console.log("📅 Total Days:", totalDays);
  console.log("💰 Total Amount:", totalAmount);

  const walletBalance = effectiveWallet(customer);
  if (walletBalance < totalAmount) {
    const shown = Math.max(0, walletBalance);
    throw new ApiError(
      400,
      `Insufficient wallet balance. Available: ₹${shown}, Required: ₹${totalAmount}`
    );
  }

  const session = await mongoose.startSession();
  session.startTransaction();

  let subscription;
  try {
    [subscription] = await Subscription.create(
      [
        {
          ownerId,
          customerId,
          planId,
          startDate,
          endDate,
          deliverySlot: value.deliverySlot,
          deliveryDays: value.deliveryDays,
          status: "active",
          totalAmount,
          paidAmount: totalAmount,
          remainingBalance: totalAmount,
          autoRenew: value.autoRenew ?? false,
          notes: value.notes,
        },
      ],
      { session }
    );

    await Customer.findByIdAndUpdate(
      customerId,
      { $inc: { walletBalance: -totalAmount, balance: -totalAmount } },
      { session }
    );

    await session.commitTransaction();
    session.endSession();
  } catch (err) {
    await session.abortTransaction();
    session.endSession();
    throw err;
  }

  const customerAfterWallet = await Customer.findById(customerId).lean();
  await notifyIfWalletJustHitZero({
    ownerId,
    customerId,
    customerBefore: customer,
    customerAfter: customerAfterWallet,
  });

  await sendNotification({
    customerId: subscription.customerId,
    ownerId: ownerId.toString(),
    type: NOTIFICATION_TYPES.SUBSCRIPTION_ACTIVATED,
    title: "Subscription activated",
    message: "Your meal subscription is now active",
    data: { subscriptionId: subscription._id },
  }).catch(() => {});

  console.log("✅ Subscription Created:", subscription._id);

  // Generate first day orders
  await generateDailyOrdersForDate(ownerId, startDate);

  const created = await Subscription.findById(subscription._id)
    .populate("customerId", "name phone address")
    .populate("planId", "planName price planType")
    .lean();

  console.log("========== CREATE SUBSCRIPTION SUCCESS ==========");

  const response = new ApiResponse(
    201,
    "Subscription created successfully",
    created
  );

  res.status(response.statusCode).json({
    success: response.success,
    message: response.message,
    data: response.data,
  });
});

/**
 * PUT /api/v1/subscriptions/:id/renew
 */
export const renewSubscription = asyncHandler(async (req, res) => {
  const ownerId = req.user.userId;
  const { id } = req.params;

  const { error, value } = renewSubscriptionSchema.validate(req.body || {}, {
    stripUnknown: true,
    abortEarly: false,
  });
  if (error) {
    throw new ApiError(400, error.details.map((d) => d.message).join("; "));
  }

  const subscription = await Subscription.findOne({ _id: id, ownerId })
    .populate("planId")
    .lean();

  if (!subscription) {
    throw new ApiError(404, "Subscription not found");
  }

  if (subscription.status === "cancelled") {
    throw new ApiError(400, "Cannot renew a cancelled subscription");
  }

  const plan = subscription.planId;
  if (!plan || !plan.isActive) {
    throw new ApiError(400, "Plan is not active or not found");
  }
  const startDate = new Date(value.startDate);
  const endDate = new Date(value.endDate);
  const totalDays =
    (endDate.getTime() - startDate.getTime()) / (1000 * 60 * 60 * 24) + 1;
  const totalAmount = plan.price * totalDays;

  const customer = await Customer.findOne({
    _id: subscription.customerId,
    ownerId,
    isDeleted: { $ne: true },
  }).lean();
  if (!customer) {
    throw new ApiError(404, "Customer not found");
  }

  const walletBalance = effectiveWallet(customer);
  if (walletBalance < totalAmount) {
    const shown = Math.max(0, walletBalance);
    throw new ApiError(
      400,
      `Insufficient wallet balance. Available: ₹${shown}, Required: ₹${totalAmount}`
    );
  }

  const session = await mongoose.startSession();
  session.startTransaction();

  let updated;
  try {
    updated = await Subscription.findOneAndUpdate(
      { _id: id, ownerId },
      {
        $set: {
          startDate,
          endDate,
          status: "active",
          totalAmount,
          paidAmount: totalAmount,
          remainingBalance: totalAmount,
        },
        // Renew = new term; remove pause fields entirely (MongoDB $unset).
        $unset: { pausedFrom: 1, pausedUntil: 1 },
      },
      { new: true, runValidators: true, session }
    )
      .populate("customerId", "name phone address")
      .populate("planId", "planName price planType");

    await Customer.findByIdAndUpdate(
      subscription.customerId,
      { $inc: { walletBalance: -totalAmount, balance: -totalAmount } },
      { session }
    );

    await session.commitTransaction();
    session.endSession();
    updated = updated?.toObject ? updated.toObject() : updated;
  } catch (err) {
    await session.abortTransaction();
    session.endSession();
    throw err;
  }

  const customerAfterRenew = await Customer.findById(subscription.customerId).lean();
  await notifyIfWalletJustHitZero({
    ownerId,
    customerId: subscription.customerId,
    customerBefore: customer,
    customerAfter: customerAfterRenew,
  });

  const response = new ApiResponse(200, "Subscription renewed", updated);
  res.status(response.statusCode).json({
    success: response.success,
    message: response.message,
    data: response.data,
  });
});

/**
 * PUT /api/v1/subscriptions/:id/pause
 * Body: { pausedFrom, pausedUntil } — ISO date strings
 * Allowed for vendor/admin (by ownerId) and customer (by customerId).
 */
export const pauseSubscription = asyncHandler(async (req, res) => {
  const role = req.user.role;
  const ownerId = role === "customer" ? req.user.ownerId : req.user.userId;
  const { id } = req.params;

  const { error, value } = pauseSchema.validate(req.body, {
    abortEarly: false,
    stripUnknown: true,
  });
  if (error) {
    throw new ApiError(400, error.details.map((d) => d.message).join("; "));
  }

  const filter = { _id: id, ownerId };
  if (role === "customer") {
    filter.customerId = req.user.customerId;
  }

  const subscription = await Subscription.findOne(filter);
  if (!subscription) {
    throw new ApiError(404, "Subscription not found");
  }

  if (subscription.status !== "active") {
    throw new ApiError(
      400,
      `Cannot pause a subscription with status '${subscription.status}'`
    );
  }

  const pausedFrom = new Date(value.pausedFrom);
  const pausedUntil = new Date(value.pausedUntil);

  const today = new Date();
  today.setHours(0, 0, 0, 0);

  if (pausedFrom < today) {
    throw new ApiError(400, "pausedFrom must be today or a future date");
  }

  if (pausedUntil > subscription.endDate) {
    throw new ApiError(400, "pausedUntil cannot be after the subscription endDate");
  }

  const updated = await Subscription.findByIdAndUpdate(
    id,
    { $set: { status: "paused", pausedFrom, pausedUntil } },
    { new: true, runValidators: true }
  )
    .populate("customerId", "name phone address")
    .populate("planId", "planName price planType")
    .lean();

  const response = new ApiResponse(200, "Subscription paused", updated);
  res.status(response.statusCode).json({
    success: response.success,
    message: response.message,
    data: response.data,
  });
});

/**
 * PUT /api/v1/subscriptions/:id/unpause
 * Allowed for vendor/admin (by ownerId) and customer (by customerId).
 */
export const unpauseSubscription = asyncHandler(async (req, res) => {
  const role = req.user.role;
  const ownerId = role === "customer" ? req.user.ownerId : req.user.userId;
  const { id } = req.params;

  const filter = { _id: id, ownerId };
  if (role === "customer") {
    filter.customerId = req.user.customerId;
  }

  const subscription = await Subscription.findOne(filter);
  if (!subscription) {
    throw new ApiError(404, "Subscription not found");
  }

  if (subscription.status !== "paused") {
    throw new ApiError(
      400,
      `Subscription is not paused (current status: '${subscription.status}')`
    );
  }

  const updated = await Subscription.findByIdAndUpdate(
    id,
    {
      $set: { status: "active" },
      $unset: { pausedFrom: "", pausedUntil: "" },
    },
    { new: true, runValidators: true }
  )
    .populate("customerId", "name phone address")
    .populate("planId", "planName price planType")
    .lean();

  const response = new ApiResponse(200, "Subscription unpaused", updated);
  res.status(response.statusCode).json({
    success: response.success,
    message: response.message,
    data: response.data,
  });
});

/**
 * PUT /api/v1/subscriptions/:id/cancel
 */
export const cancelSubscription = asyncHandler(async (req, res) => {
  const ownerId = req.user.userId;
  const { id } = req.params;

  const subscription = await Subscription.findOne({ _id: id, ownerId });
  if (!subscription) {
    throw new ApiError(404, "Subscription not found");
  }

  if (subscription.status === "cancelled") {
    throw new ApiError(400, "Subscription is already cancelled");
  }

  const updated = await Subscription.findByIdAndUpdate(
    id,
    { $set: { status: "cancelled" } },
    { new: true, runValidators: true }
  )
    .populate("customerId", "name phone address")
    .populate("planId", "planName price planType")
    .lean();

  const response = new ApiResponse(200, "Subscription cancelled", updated);
  res.status(response.statusCode).json({
    success: response.success,
    message: response.message,
    data: response.data,
  });
});

/**
 * DELETE /api/v1/subscriptions/:id
 * Permanently removes the subscription document (vendor/admin).
 * Prefer PUT /:id/cancel for a reversible “cancelled” state.
 */
export const deleteSubscription = asyncHandler(async (req, res) => {
  const ownerId = req.user.userId;
  const { id } = req.params;

  const existing = await Subscription.findOne({ _id: id, ownerId })
    .populate("customerId", "name phone address")
    .populate("planId", "planName price planType")
    .lean();

  if (!existing) {
    throw new ApiError(404, "Subscription not found");
  }

  await Subscription.deleteOne({ _id: id, ownerId });

  const response = new ApiResponse(200, "Subscription deleted", existing);
  res.status(response.statusCode).json({
    success: response.success,
    message: response.message,
    data: response.data,
  });
});
