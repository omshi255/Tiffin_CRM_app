import Joi from "joi";
import mongoose from "mongoose";
import Subscription, {
  SUBSCRIPTION_STATUSES,
  BILLING_PERIODS,
} from "../models/Subscription.model.js";
import Customer from "../models/Customer.model.js";
import Plan from "../models/Plan.model.js";
import { computeEndDate } from "../services/subscription.service.js";
import { asyncHandler } from "../utils/asyncHandler.js";
import { ApiResponse } from "../class/apiResponseClass.js";
import { ApiError } from "../class/apiErrorClass.js";

const MAX_LIMIT = 100;
const DEFAULT_LIMIT = 20;
const DEFAULT_PAGE = 1;

const createSubscriptionSchema = Joi.object({
  customerId: Joi.string().hex().length(24).required(),
  planId: Joi.string().hex().length(24).required(),
  startDate: Joi.date().iso().optional(),
  billingPeriod: Joi.string()
    .valid(...BILLING_PERIODS)
    .optional(),
  autoRenew: Joi.boolean().optional(),
});

const renewSubscriptionSchema = Joi.object({
  startDate: Joi.date().iso().optional(),
  billingPeriod: Joi.string()
    .valid(...BILLING_PERIODS)
    .optional(),
}).optional();

const listQuerySchema = Joi.object({
  page: Joi.number().integer().min(1).optional(),
  limit: Joi.number().integer().min(1).max(MAX_LIMIT).optional(),
  status: Joi.string().valid(...SUBSCRIPTION_STATUSES).optional(),
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

  const filter = {};
  if (value.status) filter.status = value.status;
  if (value.customerId) filter.customerId = value.customerId;

  const [data, total] = await Promise.all([
    Subscription.find(filter)
      .populate("customerId", "name phone address")
      .populate("planId", "name price frequency type")
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .lean(),
    Subscription.countDocuments(filter),
  ]);

  const totalPages = Math.ceil(total / limit);

  const response = new ApiResponse(200, "Subscriptions fetched", {
    data,
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
  const { id } = req.params;
  const subscription = await Subscription.findById(id)
    .populate("customerId", "name phone address")
    .populate("planId", "name price frequency type")
    .lean();

  if (!subscription) {
    throw new ApiError(404, "Subscription not found");
  }

  const response = new ApiResponse(200, "Subscription fetched", subscription);
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
  const { error, value } = createSubscriptionSchema.validate(req.body, {
    stripUnknown: true,
    abortEarly: false,
  });
  if (error) {
    throw new ApiError(400, error.details.map((d) => d.message).join("; "));
  }

  const customerId = new mongoose.Types.ObjectId(value.customerId);
  const planId = new mongoose.Types.ObjectId(value.planId);

  const [customer, plan] = await Promise.all([
    Customer.findOne({ _id: customerId, isDeleted: { $ne: true } }).lean(),
    Plan.findById(planId).lean(),
  ]);

  if (!customer) {
    throw new ApiError(404, "Customer not found");
  }
  if (!plan) {
    throw new ApiError(404, "Plan not found");
  }
  if (!plan.isActive) {
    throw new ApiError(400, "Plan is not active");
  }

  const billingPeriod = value.billingPeriod || plan.frequency || "monthly";
  const startDate = value.startDate ? new Date(value.startDate) : new Date();
  startDate.setHours(0, 0, 0, 0);

  const endDate = computeEndDate(startDate, billingPeriod);
  const price = plan.price;

  const subscription = await Subscription.create({
    customerId,
    planId,
    startDate,
    endDate,
    status: "active",
    billingPeriod,
    autoRenew: value.autoRenew ?? false,
    price,
  });

  const created = await Subscription.findById(subscription._id)
    .populate("customerId", "name phone address")
    .populate("planId", "name price frequency type")
    .lean();

  const response = new ApiResponse(201, "Subscription created", created);
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
  const { id } = req.params;

  const { error, value } = renewSubscriptionSchema.validate(req.body || {}, {
    stripUnknown: true,
    abortEarly: false,
  });
  if (error) {
    throw new ApiError(400, error.details.map((d) => d.message).join("; "));
  }

  const subscription = await Subscription.findById(id)
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

  const billingPeriod = value?.billingPeriod || subscription.billingPeriod || plan.frequency || "monthly";
  const startDate = value?.startDate
    ? new Date(value.startDate)
    : new Date(Math.max(Date.now(), new Date(subscription.endDate).getTime()));
  startDate.setHours(0, 0, 0, 0);

  const endDate = computeEndDate(startDate, billingPeriod);
  const price = plan.price;

  const updated = await Subscription.findByIdAndUpdate(
    id,
    {
      $set: {
        startDate,
        endDate,
        status: "active",
        billingPeriod,
        price,
      },
    },
    { new: true, runValidators: true }
  )
    .populate("customerId", "name phone address")
    .populate("planId", "name price frequency type")
    .lean();

  const response = new ApiResponse(200, "Subscription renewed", updated);
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
  const { id } = req.params;

  const subscription = await Subscription.findById(id);
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
    .populate("planId", "name price frequency type")
    .lean();

  const response = new ApiResponse(200, "Subscription cancelled", updated);
  res.status(response.statusCode).json({
    success: response.success,
    message: response.message,
    data: response.data,
  });
});
