import Joi from "joi";
import mongoose from "mongoose";
import Payment, {
  PAYMENT_METHODS,
  PAYMENT_STATUSES,
} from "../models/Payment.model.js";
import Customer from "../models/Customer.model.js";
import Subscription from "../models/Subscription.model.js";
import { createRazorpayOrder } from "../services/payment.service.js";
import { generateInvoice } from "../services/pdf.service.js";
import { asyncHandler } from "../utils/asyncHandler.js";
import { ApiResponse } from "../class/apiResponseClass.js";
import { ApiError } from "../class/apiErrorClass.js";
import config from "../config/index.js";

const MAX_LIMIT = 100;
const DEFAULT_LIMIT = 20;
const DEFAULT_PAGE = 1;

const createPaymentSchema = Joi.object({
  customerId: Joi.string().hex().length(24).required(),
  subscriptionId: Joi.string().hex().length(24).optional(),
  amount: Joi.number().min(0).required(),
  method: Joi.string()
    .valid(...PAYMENT_METHODS)
    .required(),
  status: Joi.string()
    .valid(...PAYMENT_STATUSES)
    .optional(),
});

const createOrderSchema = Joi.object({
  amount: Joi.number().min(1).required(),
  receipt: Joi.string().required(),
  customerId: Joi.string().hex().length(24).optional(),
  subscriptionId: Joi.string().hex().length(24).optional(),
});

const listQuerySchema = Joi.object({
  page: Joi.number().integer().min(1).optional(),
  limit: Joi.number().integer().min(1).max(MAX_LIMIT).optional(),
  customerId: Joi.string().hex().length(24).optional(),
  fromDate: Joi.date().iso().optional(),
  toDate: Joi.date().iso().optional(),
});

/**
 * GET /api/v1/payments
 * Query: page, limit, customerId, fromDate, toDate
 */
export const listPayments = asyncHandler(async (req, res) => {
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
  if (value.customerId) filter.customerId = value.customerId;
  if (value.fromDate || value.toDate) {
    filter.createdAt = {};
    if (value.fromDate) filter.createdAt.$gte = new Date(value.fromDate);
    if (value.toDate) filter.createdAt.$lte = new Date(value.toDate);
  }

  const [data, total] = await Promise.all([
    Payment.find(filter)
      .populate("customerId", "name phone address")
      .populate("subscriptionId", "planId startDate endDate")
      .sort({ createdAt: -1 })
      .skip(skip)
      .limit(limit)
      .lean(),
    Payment.countDocuments(filter),
  ]);

  const totalPages = Math.ceil(total / limit);

  const response = new ApiResponse(200, "Payments fetched", {
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
 * POST /api/v1/payments
 * Manual payment: amount, method, customerId, subscriptionId?
 */
export const createPayment = asyncHandler(async (req, res) => {
  const { error, value } = createPaymentSchema.validate(req.body, {
    stripUnknown: true,
    abortEarly: false,
  });
  if (error) {
    throw new ApiError(400, error.details.map((d) => d.message).join("; "));
  }

  const customerId = new mongoose.Types.ObjectId(value.customerId);
  const customer = await Customer.findOne({
    _id: customerId,
    isDeleted: { $ne: true },
  });
  if (!customer) {
    throw new ApiError(404, "Customer not found");
  }

  let subscriptionId = null;
  if (value.subscriptionId) {
    subscriptionId = new mongoose.Types.ObjectId(value.subscriptionId);
    const sub = await Subscription.findById(subscriptionId);
    if (!sub) {
      throw new ApiError(404, "Subscription not found");
    }
  }

  const payment = await Payment.create({
    customerId,
    subscriptionId: subscriptionId || undefined,
    amount: value.amount,
    method: value.method,
    status: value.status || "captured",
  });

  const created = await Payment.findById(payment._id)
    .populate("customerId", "name phone address")
    .populate("subscriptionId", "planId startDate endDate")
    .lean();

  const response = new ApiResponse(201, "Payment created", created);
  res.status(response.statusCode).json({
    success: response.success,
    message: response.message,
    data: response.data,
  });
});

/**
 * POST /api/v1/payments/create-order
 * Create Razorpay order; return order_id and key_id for Flutter.
 */
export const createOrder = asyncHandler(async (req, res) => {
  const { error, value } = createOrderSchema.validate(req.body, {
    stripUnknown: true,
    abortEarly: false,
  });
  if (error) {
    throw new ApiError(400, error.details.map((d) => d.message).join("; "));
  }

  if (!config.RAZORPAY_KEY_ID || !config.RAZORPAY_KEY_SECRET) {
    throw new ApiError(503, "Razorpay is not configured");
  }

  let paymentId = value.receipt;
  if (value.customerId) {
    const customer = await Customer.findOne({
      _id: value.customerId,
      isDeleted: { $ne: true },
    });
    if (!customer) throw new ApiError(404, "Customer not found");
    let subId = null;
    if (value.subscriptionId) {
      const sub = await Subscription.findById(value.subscriptionId);
      if (!sub) throw new ApiError(404, "Subscription not found");
      subId = value.subscriptionId;
    }
    const payment = await Payment.create({
      customerId: value.customerId,
      subscriptionId: subId || undefined,
      amount: value.amount,
      method: "razorpay",
      status: "pending",
    });
    paymentId = payment._id.toString();
  }

  const { orderId, keyId } = await createRazorpayOrder(value.amount, paymentId);

  if (value.customerId) {
    await Payment.findOneAndUpdate(
      { _id: paymentId },
      { $set: { razorpayOrderId: orderId } }
    );
  }

  const response = new ApiResponse(200, "Order created", {
    orderId,
    keyId,
    amount: value.amount,
    receipt: paymentId,
    ...(value.customerId && { paymentId }),
  });

  res.status(response.statusCode).json({
    success: response.success,
    message: response.message,
    data: response.data,
  });
});

/**
 * GET /api/v1/payments/:id/invoice
 * Redirect to invoice URL or generate + redirect
 */
export const getInvoice = asyncHandler(async (req, res) => {
  const { id } = req.params;

  const payment = await Payment.findById(id).lean();
  if (!payment) {
    throw new ApiError(404, "Payment not found");
  }

  let invoiceUrl = payment.invoiceUrl;
  if (!invoiceUrl) {
    invoiceUrl = await generateInvoice(id);
  }

  res.redirect(302, invoiceUrl);
});
