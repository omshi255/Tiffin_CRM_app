import Joi from "joi";
import Customer, { CUSTOMER_STATUSES } from "../models/Customer.model.js";
import { asyncHandler } from "../utils/asyncHandler.js";
import { ApiResponse } from "../class/apiResponseClass.js";
import { ApiError } from "../class/apiErrorClass.js";

const MAX_LIMIT = 100;
const DEFAULT_LIMIT = 20;
const DEFAULT_PAGE = 1;

const phoneSchema = Joi.string()
  .pattern(/^[6-9]\d{9}$/)
  .required()
  .messages({
    "string.pattern.base":
      "Phone must be a valid 10-digit Indian mobile number",
  });

const createCustomerSchema = Joi.object({
  name: Joi.string()
    .trim()
    .required()
    .messages({ "string.empty": "Name is required" }),
  phone: phoneSchema,
  address: Joi.string()
    .trim()
    .required()
    .messages({ "string.empty": "Address is required" }),
  area: Joi.string().trim().allow("").optional(),
  landmark: Joi.string().trim().allow("").optional(),
  whatsapp: Joi.string().trim().allow("").optional(),
  notes: Joi.string().trim().allow("").optional(),
  tags: Joi.array().items(Joi.string().trim()).optional(),
  status: Joi.string()
    .valid(...CUSTOMER_STATUSES)
    .optional(),
  location: Joi.object({
    type: Joi.string().valid("Point").optional(),
    coordinates: Joi.array().items(Joi.number()).length(2).optional(), // [lng, lat]
  }).optional(),
});

const updateCustomerSchema = Joi.object({
  name: Joi.string().trim().optional(),
  phone: Joi.string()
    .pattern(/^[6-9]\d{9}$/)
    .optional(),
  address: Joi.string().trim().allow("").optional(),
  area: Joi.string().trim().allow("").optional(),
  landmark: Joi.string().trim().allow("").optional(),
  whatsapp: Joi.string().trim().allow('"').optional(),
  notes: Joi.string().trim().allow('"').optional(),
  tags: Joi.array().items(Joi.string().trim()).optional(),
  status: Joi.string()
    .valid(...CUSTOMER_STATUSES)
    .optional(),
  isDeleted: Joi.boolean().optional(),
  location: Joi.object({
    type: Joi.string().valid("Point").optional(),
    coordinates: Joi.array().items(Joi.number()).length(2).optional(),
  }).optional(),
}).min(1);

const listQuerySchema = Joi.object({
  page: Joi.number().integer().min(1).optional(),
  limit: Joi.number().integer().min(1).max(MAX_LIMIT).optional(),
  status: Joi.string()
    .valid(...CUSTOMER_STATUSES)
    .optional(),
});

const bulkCustomerItemSchema = Joi.object({
  name: Joi.string()
    .trim()
    .required()
    .messages({ "string.empty": "Name is required" }),
  phone: phoneSchema,
  address: Joi.string().trim().allow("").optional(),
  status: Joi.string()
    .valid(...CUSTOMER_STATUSES)
    .optional(),
  whatsapp: Joi.string().trim().allow("").optional(),
});

const bulkCreateSchema = Joi.object({
  customers: Joi.array()
    .items(bulkCustomerItemSchema)
    .min(1)
    .max(100)
    .required(),
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

  const ownerId = req.user.userId;
  const filter = { ownerId, isDeleted: { $ne: true } };
  if (value.status) filter.status = value.status;

  const [data, total] = await Promise.all([
    Customer.find(filter)
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .lean(),
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
  const ownerId = req.user.userId;
  const { id } = req.params;
  const customer = await Customer.findOne({
    _id: id,
    ownerId,
    isDeleted: { $ne: true },
  }).lean();

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

  const ownerId = req.user.userId;

  const phone = String(value.phone)
    .trim()
    .replace(/^\+?91/, "");
  const existing = await Customer.findOne({
    phone,
    ownerId,
    isDeleted: { $ne: true },
  });
  if (existing) {
    throw new ApiError(409, "Customer with this phone already exists");
  }

  const payload = {
    ownerId,
    name: value.name.trim(),
    phone,
    address: value.address || "",
    area: value.area || "",
    landmark: value.landmark || "",
    status: value.status || "active",
    whatsapp: value.whatsapp || null,
    notes: value.notes || "",
    tags: value.tags || [],
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
  const ownerId = req.user.userId;
  const { id } = req.params;

  const { error, value } = updateCustomerSchema.validate(req.body, {
    stripUnknown: true,
    abortEarly: false,
  });
  if (error) {
    throw new ApiError(400, error.details.map((d) => d.message).join("; "));
  }

  const customer = await Customer.findOne({
    _id: id,
    ownerId,
    isDeleted: { $ne: true },
  });
  if (!customer) {
    throw new ApiError(404, "Customer not found");
  }

  if (value.phone) {
    const phone = String(value.phone)
      .trim()
      .replace(/^\+?91/, "");
    const existing = await Customer.findOne({
      phone,
      _id: { $ne: id },
      isDeleted: { $ne: true },
    });
    if (existing) {
      throw new ApiError(
        409,
        "Another customer with this phone already exists"
      );
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

/**
 * POST /api/v1/customers/bulk
 * Body: { customers: [{ name, phone, address?, ... }] }
 * Rate limited: 5 req/15 min
 */
export const bulkCreateCustomers = asyncHandler(async (req, res) => {
  const ownerId = req.user.userId;
  const { error, value } = bulkCreateSchema.validate(req.body, {
    stripUnknown: true,
    abortEarly: false,
  });
  if (error) {
    throw new ApiError(400, error.details.map((d) => d.message).join("; "));
  }

  const phones = value.customers.map((c) =>
    String(c.phone)
      .trim()
      .replace(/^\+?91/, "")
  );
  const existingCustomers = await Customer.find({
    ownerId,
    phone: { $in: phones },
    isDeleted: { $ne: true },
  })
    .select("phone")
    .lean();

  const existingPhones = new Set(existingCustomers.map((c) => c.phone));

  const toInsert = [];
  for (const c of value.customers) {
    const phone = String(c.phone)
      .trim()
      .replace(/^\+?91/, "");
    if (existingPhones.has(phone)) continue;
    existingPhones.add(phone); // avoid duplicates within batch
    toInsert.push({
      ownerId,
      name: c.name.trim(),
      phone,
      address: c.address || "",
      area: c.area || "",
      landmark: c.landmark || "",
      status: c.status || "active",
      whatsapp: c.whatsapp || null,
      notes: c.notes || "",
      tags: c.tags || [],
    });
  }

  if (toInsert.length === 0) {
    throw new ApiError(400, "All phones already exist or duplicates in batch");
  }

  const inserted = await Customer.insertMany(toInsert);
  const skipped = value.customers.length - toInsert.length;

  const response = new ApiResponse(201, "Bulk import completed", {
    created: inserted.length,
    skipped,
    data: inserted.map((c) => c.toObject()),
  });

  res.status(response.statusCode).json({
    success: response.success,
    message: response.message,
    data: response.data,
  });
});

/**
 * DELETE /api/v1/customers/:id
 * Soft delete: sets isDeleted: true
 */
export const deleteCustomer = asyncHandler(async (req, res) => {
  const ownerId = req.user.userId;
  const { id } = req.params;

  const customer = await Customer.findOne({
    _id: id,
    ownerId,
    isDeleted: { $ne: true },
  });
  if (!customer) {
    throw new ApiError(404, "Customer not found");
  }

  const updated = await Customer.findByIdAndUpdate(
    id,
    { $set: { isDeleted: true } },
    { new: true }
  ).lean();

  const response = new ApiResponse(200, "Customer deleted (soft)", updated);
  res.status(response.statusCode).json({
    success: response.success,
    message: response.message,
    data: response.data,
  });
});
