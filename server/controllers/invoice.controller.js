import Joi from "joi";
import mongoose from "mongoose";
import Invoice from "../models/Invoice.model.js";
import DailyOrder from "../models/DailyOrder.model.js";
import User from "../models/User.model.js";
import Customer from "../models/Customer.model.js";
import { asyncHandler } from "../utils/asyncHandler.js";
import { ApiResponse } from "../class/apiResponseClass.js";
import { ApiError } from "../class/apiErrorClass.js";
import { sendNotification } from "../services/inAppNotification.service.js";

const listQuerySchema = Joi.object({
  customerId: Joi.string().hex().length(24).optional(),
  paymentStatus: Joi.string().valid("unpaid", "partial", "paid").optional(),
  month: Joi.string()
    .pattern(/^\d{4}-\d{2}$/)
    .optional(), // YYYY-MM
});

const generateSchema = Joi.object({
  customerId: Joi.string().hex().length(24).required(),
  subscriptionId: Joi.string().hex().length(24).optional(),
  billingStart: Joi.date().iso().required(),
  billingEnd: Joi.date().iso().min(Joi.ref("billingStart")).required(),
});

export const listInvoices = asyncHandler(async (req, res) => {
  const ownerId = req.user.userId;
  const { error, value } = listQuerySchema.validate(req.query, {
    stripUnknown: true,
    abortEarly: false,
  });
  if (error) {
    throw new ApiError(400, error.details.map((d) => d.message).join("; "));
  }

  const filter = { ownerId };
  if (value.customerId) filter.customerId = value.customerId;
  if (value.paymentStatus) filter.paymentStatus = value.paymentStatus;
  if (value.month) {
    const [year, month] = value.month.split("-").map(Number);
    const start = new Date(year, month - 1, 1);
    const end = new Date(year, month, 0, 23, 59, 59, 999);
    filter.billingStart = { $gte: start };
    filter.billingEnd = { $lte: end };
  }

  const invoices = await Invoice.find(filter)
    .populate("customerId", "name phone area")
    .sort({ createdAt: -1 })
    .lean();

  const response = new ApiResponse(200, "Invoices fetched", invoices);
  res.status(response.statusCode).json(response);
});

export const generateInvoiceForRange = asyncHandler(async (req, res) => {
  const ownerId = req.user.userId;
  const { error, value } = generateSchema.validate(req.body, {
    stripUnknown: true,
    abortEarly: false,
  });
  if (error) {
    throw new ApiError(400, error.details.map((d) => d.message).join("; "));
  }

  const customerId = new mongoose.Types.ObjectId(value.customerId);
  const billingStart = new Date(value.billingStart);
  const billingEnd = new Date(value.billingEnd);

  const [owner, customer] = await Promise.all([
    User.findById(ownerId),
    Customer.findOne({ _id: customerId, ownerId }),
  ]);

  if (!owner) throw new ApiError(404, "Vendor account not found");

  if (!customer) throw new ApiError(404, "Customer not found");

  // fetch delivered orders first
  let orders = await DailyOrder.find({
    ownerId,
    customerId,
    status: "delivered",
    orderDate: { $gte: billingStart, $lte: billingEnd },
  }).lean();

  let usedFallback = false;
  if (!orders.length) {
    // try any order (pending/processing) so invoice can still be generated
    orders = await DailyOrder.find({
      ownerId,
      customerId,
      status: { $in: ["pending", "processing"] },
      orderDate: { $gte: billingStart, $lte: billingEnd },
    }).lean();
    if (orders.length) {
      usedFallback = true;
      console.warn(
        `Invoice fallback: using ${orders.length} non-delivered orders for customer ${customerId}`
      );
    }
  }

  if (!orders.length) {
    throw new ApiError(400, "No orders in this range");
  }

  // Build one line item per order using the actual order amount.
  const lineItems = orders.map((order) => ({
    description: `Tiffin delivery — ${new Date(order.orderDate).toDateString()}`,
    quantity: 1,
    unitPrice: order.amount ?? 0,
    amount: order.amount ?? 0,
  }));

  const subtotal = lineItems.reduce((sum, li) => sum + li.amount, 0);
  const netAmount = subtotal;

  const updatedOwner = await User.findByIdAndUpdate(
    ownerId,
    { $inc: { invoiceCounter: 1 } },
    { new: true }
  );

  if (!updatedOwner)
    throw new ApiError(500, "Failed to update invoice counter");

  const year = new Date().getFullYear();
  const invoiceNumber = `INV-${year}-${String(updatedOwner.invoiceCounter).padStart(3, "0")}`;

  const invoice = await Invoice.create({
    ownerId,
    customerId,
    subscriptionId: value.subscriptionId || undefined,
    invoiceNumber,
    billingStart,
    billingEnd,
    lineItems,
    subtotal,
    netAmount,
    paidAmount: 0,
    balanceDue: netAmount,
    paymentStatus: "unpaid",
  });

  await sendNotification({
    customerId: invoice.customerId,
    ownerId: ownerId.toString(),
    title: "Invoice ready",
    message: `Invoice ${invoice.invoiceNumber} generated`,
    data: { invoiceId: invoice._id.toString() },
  }).catch(() => {});

  const response = new ApiResponse(201, "Invoice generated", {
    ...invoice.toObject(),
    ...(usedFallback && { warning: "Generated using non-delivered orders" }),
  });
  res.status(response.statusCode).json(response);
});

export const getInvoiceById = asyncHandler(async (req, res) => {
  const ownerId = req.user.userId;
  const { id } = req.params;

  const invoice = await Invoice.findOne({ _id: id, ownerId })
    .populate("customerId", "name phone address")
    .lean();
  if (!invoice) throw new ApiError(404, "Invoice not found");

  const response = new ApiResponse(200, "Invoice fetched", invoice);
  res.status(response.statusCode).json(response);
});

export const updateInvoice = asyncHandler(async (req, res) => {
  const ownerId = req.user.userId;
  const { id } = req.params;
  const { notes, dueDate } = req.body;

  const invoice = await Invoice.findOne({ _id: id, ownerId });
  if (!invoice) throw new ApiError(404, "Invoice not found");
  if (invoice.paymentStatus === "paid") {
    throw new ApiError(400, "Cannot edit a paid invoice");
  }

  if (notes !== undefined) invoice.notes = notes;
  if (dueDate) invoice.dueDate = new Date(dueDate);

  await invoice.save();

  const response = new ApiResponse(200, "Invoice updated", invoice);
  res.status(response.statusCode).json(response);
});

export const shareInvoice = asyncHandler(async (req, res) => {
  const ownerId = req.user.userId;
  const { id } = req.params;

  const invoice = await Invoice.findOne({ _id: id, ownerId });
  if (!invoice) throw new ApiError(404, "Invoice not found");

  const token = (await import("crypto")).randomBytes(32).toString("hex");
  const expiresAt = new Date(Date.now() + 48 * 60 * 60 * 1000);

  invoice.shareToken = token;
  invoice.shareTokenExpiresAt = expiresAt;
  await invoice.save();

  const base = process.env.SHARE_LINK_BASE || process.env.PUBLIC_URL || "";
  const url = `${base}/public/invoice/${token}`;

  const response = new ApiResponse(200, "Share link created", { url });
  res.status(response.statusCode).json(response);
});

export const voidInvoice = asyncHandler(async (req, res) => {
  const ownerId = req.user.userId;
  const { id } = req.params;

  const invoice = await Invoice.findOne({ _id: id, ownerId });
  if (!invoice) throw new ApiError(404, "Invoice not found");

  invoice.isVoid = true;
  await invoice.save();

  const response = new ApiResponse(200, "Invoice voided", invoice);
  res.status(response.statusCode).json(response);
});

export const getOverdueInvoices = asyncHandler(async (req, res) => {
  const ownerId = req.user.userId;
  const today = new Date();

  const invoices = await Invoice.find({
    ownerId,
    dueDate: { $lt: today },
    balanceDue: { $gt: 0 },
    isVoid: { $ne: true },
  })
    .populate("customerId", "name phone")
    .lean();

  const response = new ApiResponse(200, "Overdue invoices fetched", invoices);
  res.status(response.statusCode).json(response);
});
