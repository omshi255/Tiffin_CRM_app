import Joi from "joi";
import Customer, { CUSTOMER_TYPES, CUSTOMER_STATUSES } from "../models/Customer.model.js";
import { asyncHandler } from "../utils/asyncHandler.js";
import { ApiResponse } from "../class/apiResponseClass.js";
import { ApiError } from "../class/apiErrorClass.js";

const MAX_LIMIT = 100;
const DEFAULT_LIMIT = 20;
const DEFAULT_PAGE = 1;

const phoneSchema = Joi.string()
  .pattern(/^[6-9]\d{9}$/)
  .required()
  .messages({ "string.pattern.base": "Phone must be a valid 10-digit Indian mobile number" });

const createCustomerSchema = Joi.object({
  name: Joi.string().trim().required().messages({ "string.empty": "Name is required" }),
  phone: phoneSchema,
  address: Joi.string().trim().allow("").optional(),
  customerType: Joi.string()
    .valid(...CUSTOMER_TYPES)
    .optional(),
  status: Joi.string()
    .valid(...CUSTOMER_STATUSES)
    .optional(),
  whatsapp: Joi.string().trim().allow("").optional(),
  location: Joi.object({
    type: Joi.string().valid("Point").optional(),
    coordinates: Joi.array().items(Joi.number()).length(2).optional(), // [lng, lat]
  }).optional(),
});

const updateCustomerSchema = Joi.object({
  name: Joi.string().trim().optional(),
  phone: Joi.string().pattern(/^[6-9]\d{9}$/).optional(),
  address: Joi.string().trim().allow("").optional(),
  customerType: Joi.string().valid(...CUSTOMER_TYPES).optional(),
  status: Joi.string().valid(...CUSTOMER_STATUSES).optional(),
  whatsapp: Joi.string().trim().allow("").optional(),
  isDeleted: Joi.boolean().optional(),
  location: Joi.object({
    type: Joi.string().valid("Point").optional(),
    coordinates: Joi.array().items(Joi.number()).length(2).optional(),
  }).optional(),
}).min(1);

const listQuerySchema = Joi.object({
  page: Joi.number().integer().min(1).optional(),
  limit: Joi.number().integer().min(1).max(MAX_LIMIT).optional(),
  status: Joi.string().valid(...CUSTOMER_STATUSES).optional(),
  customerType: Joi.string().valid(...CUSTOMER_TYPES).optional(),
});

/**
 * GET /api/v1/customers
 * Query: page, limit, status, customerType
 */
export const listCustomers = asyncHandler(async (req, res) => {
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

  const filter = { isDeleted: { $ne: true } };
  if (value.status) filter.status = value.status;
  if (value.customerType) filter.customerType = value.customerType;

  const [data, total] = await Promise.all([
    Customer.find(filter).sort({ createdAt: -1 }).skip(skip).limit(limit).lean(),
    Customer.countDocuments(filter),
  ]);

  const totalPages = Math.ceil(total / limit);

  const response = new ApiResponse(200, "Customers fetched", {
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
 * GET /api/v1/customers/:id
 */
export const getCustomerById = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const customer = await Customer.findOne({ _id: id, isDeleted: { $ne: true } }).lean();

  if (!customer) {
    throw new ApiError(404, "Customer not found");
  }

  const response = new ApiResponse(200, "Customer fetched", customer);
  res.status(response.statusCode).json({
    success: response.success,
    message: response.message,
    data: response.data,
  });
});

/**
 * POST /api/v1/customers
 */
export const createCustomer = asyncHandler(async (req, res) => {
  const { error, value } = createCustomerSchema.validate(req.body, {
    stripUnknown: true,
    abortEarly: false,
  });
  if (error) {
    throw new ApiError(400, error.details.map((d) => d.message).join("; "));
  }

  const phone = String(value.phone).trim().replace(/^\+?91/, "");
  const existing = await Customer.findOne({ phone, isDeleted: { $ne: true } });
  if (existing) {
    throw new ApiError(409, "Customer with this phone already exists");
  }

  const payload = {
    name: value.name.trim(),
    phone,
    address: value.address || "",
    customerType: value.customerType || "individual",
    status: value.status || "active",
    whatsapp: value.whatsapp || null,
  };

  if (value.location?.coordinates?.length === 2) {
    payload.location = {
      type: "Point",
      coordinates: value.location.coordinates,
    };
  }

  const customer = await Customer.create(payload);
  const created = customer.toObject();

  const response = new ApiResponse(201, "Customer created", created);
  res.status(response.statusCode).json({
    success: response.success,
    message: response.message,
    data: response.data,
  });
});

/**
 * PUT /api/v1/customers/:id
 */
export const updateCustomer = asyncHandler(async (req, res) => {
  const { id } = req.params;

  const { error, value } = updateCustomerSchema.validate(req.body, {
    stripUnknown: true,
    abortEarly: false,
  });
  if (error) {
    throw new ApiError(400, error.details.map((d) => d.message).join("; "));
  }

  const customer = await Customer.findOne({ _id: id, isDeleted: { $ne: true } });
  if (!customer) {
    throw new ApiError(404, "Customer not found");
  }

  if (value.phone) {
    const phone = String(value.phone).trim().replace(/^\+?91/, "");
    const existing = await Customer.findOne({
      phone,
      _id: { $ne: id },
      isDeleted: { $ne: true },
    });
    if (existing) {
      throw new ApiError(409, "Another customer with this phone already exists");
    }
    value.phone = phone;
  }

  const updatePayload = { ...value };
  if (value.location?.coordinates?.length === 2) {
    updatePayload.location = {
      type: "Point",
      coordinates: value.location.coordinates,
    };
  }

  const updated = await Customer.findByIdAndUpdate(
    id,
    { $set: updatePayload },
    { new: true, runValidators: true }
  ).lean();

  const response = new ApiResponse(200, "Customer updated", updated);
  res.status(response.statusCode).json({
    success: response.success,
    message: response.message,
    data: response.data,
  });
});
