import Joi from "joi";
import Plan, { PLAN_TYPES, PLAN_FREQUENCIES } from "../models/Plan.model.js";
import { asyncHandler } from "../utils/asyncHandler.js";
import { ApiResponse } from "../class/apiResponseClass.js";
import { ApiError } from "../class/apiErrorClass.js";

const MAX_LIMIT = 100;
const DEFAULT_LIMIT = 20;
const DEFAULT_PAGE = 1;

const createPlanSchema = Joi.object({
  name: Joi.string().trim().required().messages({ "string.empty": "Name is required" }),
  type: Joi.string().valid(...PLAN_TYPES).optional(),
  price: Joi.number().min(0).required().messages({
    "number.min": "Price must be 0 or greater",
  }),
  frequency: Joi.string().valid(...PLAN_FREQUENCIES).optional(),
  description: Joi.string().trim().allow("").optional(),
  isActive: Joi.boolean().optional(),
});

const updatePlanSchema = Joi.object({
  name: Joi.string().trim().optional(),
  type: Joi.string().valid(...PLAN_TYPES).optional(),
  price: Joi.number().min(0).optional(),
  frequency: Joi.string().valid(...PLAN_FREQUENCIES).optional(),
  description: Joi.string().trim().allow("").optional(),
  isActive: Joi.boolean().optional(),
}).min(1);

const listQuerySchema = Joi.object({
  page: Joi.number().integer().min(1).optional(),
  limit: Joi.number().integer().min(1).max(MAX_LIMIT).optional(),
  isActive: Joi.boolean().optional(),
  type: Joi.string().valid(...PLAN_TYPES).optional(),
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

  const filter = {};
  if (value.isActive !== undefined) filter.isActive = value.isActive;
  if (value.type) filter.type = value.type;

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
  const { id } = req.params;
  const plan = await Plan.findById(id).lean();

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
    name: value.name.trim(),
    price: value.price,
    type: value.type || "regular",
    frequency: value.frequency || "monthly",
    description: value.description || "",
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

  const plan = await Plan.findByIdAndUpdate(
    id,
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
