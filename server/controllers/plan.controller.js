import Joi from "joi";
import Plan from "../models/Plan.model.js";
import Subscription from "../models/Subscription.model.js";
import DailyOrder from "../models/DailyOrder.model.js";
import { asyncHandler } from "../utils/asyncHandler.js";
import { ApiResponse } from "../class/apiResponseClass.js";
import { ApiError } from "../class/apiErrorClass.js";

const MAX_LIMIT = 100;
const DEFAULT_LIMIT = 20;
const DEFAULT_PAGE = 1;

const createPlanSchema = Joi.object({
  planName: Joi.string()
    .trim()
    .required()
    .messages({ "string.empty": "Plan name is required" }),
  planType: Joi.string()
    .valid("daily", "weekly", "monthly", "custom")
    .optional(),
  price: Joi.number().min(0).required().messages({
    "number.min": "Price must be 0 or greater",
  }),
  includesLunch: Joi.boolean().optional(),
  includesDinner: Joi.boolean().optional(),
  menuDescription: Joi.string().trim().allow("").optional(),
  isActive: Joi.boolean().optional(),
});

const updatePlanSchema = Joi.object({
  planName: Joi.string().trim().optional(),
  planType: Joi.string()
    .valid("daily", "weekly", "monthly", "custom")
    .optional(),
  price: Joi.number().min(0).optional(),
  includesLunch: Joi.boolean().optional(),
  includesDinner: Joi.boolean().optional(),
  menuDescription: Joi.string().trim().allow("").optional(),
  isActive: Joi.boolean().optional(),
}).min(1);

const listQuerySchema = Joi.object({
  page: Joi.number().integer().min(1).optional(),
  limit: Joi.number().integer().min(1).max(MAX_LIMIT).optional(),
  isActive: Joi.boolean().optional(),
  planType: Joi.string()
    .valid("daily", "weekly", "monthly", "custom")
    .optional(),
});

/**
 * GET /api/v1/plans
 * Query: page, limit, isActive, type
 */
export const listPlans = asyncHandler(async (req, res) => {
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
  if (value.isActive !== undefined) filter.isActive = value.isActive;
  if (value.planType) filter.planType = value.planType;

  const [data, total] = await Promise.all([
    Plan.find(filter).sort({ createdAt: -1 }).skip(skip).limit(limit).lean(),
    Plan.countDocuments(filter),
  ]);

  const totalPages = Math.ceil(total / limit);

  const response = new ApiResponse(200, "Plans fetched", {
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
 * GET /api/v1/plans/:id
 */
export const getPlanById = asyncHandler(async (req, res) => {
  const ownerId = req.user.userId;
  const { id } = req.params;
  const plan = await Plan.findOne({ _id: id, ownerId }).lean();

  if (!plan) {
    throw new ApiError(404, "Plan not found");
  }

  const response = new ApiResponse(200, "Plan fetched", plan);
  res.status(response.statusCode).json({
    success: response.success,
    message: response.message,
    data: response.data,
  });
});

/**
 * POST /api/v1/plans
 */
export const createPlan = asyncHandler(async (req, res) => {
  const { error, value } = createPlanSchema.validate(req.body, {
    stripUnknown: true,
    abortEarly: false,
  });
  if (error) {
    throw new ApiError(400, error.details.map((d) => d.message).join("; "));
  }

  const payload = {
    ownerId: req.user.userId,
    planName: value.planName.trim(),
    planType: value.planType || "monthly",
    price: value.price,
    includesLunch:
      value.includesLunch !== undefined ? value.includesLunch : true,
    includesDinner:
      value.includesDinner !== undefined ? value.includesDinner : false,
    menuDescription: value.menuDescription || "",
    isActive: value.isActive !== undefined ? value.isActive : true,
  };

  const plan = await Plan.create(payload);
  const created = plan.toObject();

  const response = new ApiResponse(201, "Plan created", created);
  res.status(response.statusCode).json({
    success: response.success,
    message: response.message,
    data: response.data,
  });
});

/**
 * PUT /api/v1/plans/:id
 */
export const updatePlan = asyncHandler(async (req, res) => {
  const { id } = req.params;

  const { error, value } = updatePlanSchema.validate(req.body, {
    stripUnknown: true,
    abortEarly: false,
  });
  if (error) {
    throw new ApiError(400, error.details.map((d) => d.message).join("; "));
  }

  const ownerId = req.user.userId;
  const plan = await Plan.findOneAndUpdate(
    { _id: id, ownerId },
    { $set: value },
    { new: true, runValidators: true }
  ).lean();

  if (!plan) {
    throw new ApiError(404, "Plan not found");
  }

  const response = new ApiResponse(200, "Plan updated", plan);
  res.status(response.statusCode).json({
    success: response.success,
    message: response.message,
    data: response.data,
  });
});

export const deletePlan = asyncHandler(async (req, res) => {
  const ownerId = req.user.userId;
  const { id } = req.params;

  const plan = await Plan.findOne({ _id: id, ownerId });

  if (!plan) {
    throw new ApiError(404, "Meal plan not found");
  }

  // Check subscriptions using this plan
  const activeSubscriptions = await Subscription.countDocuments({
    planId: id,
    status: "active",
  });

  if (activeSubscriptions > 0) {
    throw new ApiError(400, "Cannot delete plan. Active subscriptions exist.");
  }

  // Check future orders using this plan
  const futureOrders = await DailyOrder.countDocuments({
    planId: id,
    orderDate: { $gte: new Date() },
  });

  if (futureOrders > 0) {
    throw new ApiError(400, "Cannot delete plan. Orders already generated.");
  }

  await Plan.deleteOne({ _id: id });

  const response = new ApiResponse(200, "Meal plan deleted successfully");

  res.status(response.statusCode).json({
    success: response.success,
    message: response.message,
  });
});
