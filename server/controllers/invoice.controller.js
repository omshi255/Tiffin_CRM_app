import Joi from "joi";
import mongoose from "mongoose";
import Invoice from "../models/Invoice.model.js";
import DailyOrder from "../models/DailyOrder.model.js";
import User from "../models/User.model.js";
import Customer from "../models/Customer.model.js";
import Subscription from "../models/Subscription.model.js";
import Payment from "../models/Payment.model.js";
import Item from "../models/Item.model.js";
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

/** yyyy-MM-dd → UTC midnight (same as daily orders). */
const parseOrderDayUTC = (d) => {
  const [y, m, day] = d.split("-").map(Number);
  return new Date(Date.UTC(y, m - 1, day));
};

const dailyReceiptQuerySchema = Joi.object({
  customerId: Joi.string().hex().length(24).required(),
  date: Joi.string()
    .pattern(/^\d{4}-\d{2}-\d{2}$/)
    .required(),
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

/**
 * GET /api/v1/invoices/daily?customerId=&date=yyyy-MM-dd
 */
export const getDailyInvoiceReceipt = asyncHandler(async (req, res) => {
  const ownerId = req.user.userId;
  const { error, value } = dailyReceiptQuerySchema.validate(req.query, {
    stripUnknown: true,
    abortEarly: false,
  });
  if (error) {
    throw new ApiError(400, error.details.map((d) => d.message).join("; "));
  }

  const customerId = new mongoose.Types.ObjectId(value.customerId);
  const dayStart = parseOrderDayUTC(value.date);
  const dayEnd = new Date(dayStart);
  dayEnd.setUTCDate(dayEnd.getUTCDate() + 1);

  const [vendor, customer] = await Promise.all([
    User.findById(ownerId).lean(),
    Customer.findById(customerId).lean(),
  ]);
  if (!vendor) {
    throw new ApiError(404, "Vendor not found");
  }
  if (!customer) {
    throw new ApiError(404, "Customer not found");
  }
  if (customer.ownerId.toString() !== ownerId.toString()) {
    throw new ApiError(403, "Customer does not belong to this vendor");
  }

  const subscription = await Subscription.findOne({
    ownerId,
    customerId,
    startDate: { $lte: dayEnd },
    endDate: { $gte: dayStart },
  })
    .populate("planId")
    .lean();

  const orders = await DailyOrder.find({
    ownerId,
    customerId,
    orderDate: dayStart,
  })
    .sort({ mealType: 1 })
    .lean();

  const slotToDelivery = new Map();

  const addDelivery = (slotKey, items) => {
    if (!slotToDelivery.has(slotKey)) {
      slotToDelivery.set(slotKey, { slot: slotKey, items: [] });
    }
    const d = slotToDelivery.get(slotKey);
    d.items.push(...items);
  };

  let subtotal = 0;

  if (orders.length) {
    for (const order of orders) {
      const slotKey = order.mealType || "meal";

      const lineItems = [];
      if (order.resolvedItems?.length) {
        for (const ri of order.resolvedItems) {
          const qty = ri.quantity ?? 1;
          const unitPrice = ri.unitPrice ?? 0;
          const lineTotal =
            ri.subtotal != null ? ri.subtotal : qty * unitPrice;
          subtotal += lineTotal;
          lineItems.push({
            name: ri.itemName || "Item",
            quantity: qty,
            unitPrice,
            total: lineTotal,
            unit: "unit",
          });
        }
      } else if (order.amount != null) {
        subtotal += order.amount;
        lineItems.push({
          name: "Order",
          quantity: 1,
          unitPrice: order.amount,
          total: order.amount,
          unit: "unit",
        });
      }

      addDelivery(slotKey, lineItems);
    }
  } else if (subscription?.planId) {
    const plan = subscription.planId;
    const mealSlots = plan.mealSlots || [];
    const itemIds = [
      ...new Set(
        mealSlots.flatMap((s) =>
          (s.items || []).map((i) => i.itemId).filter(Boolean)
        )
      ),
    ];

    const items = itemIds.length
      ? await Item.find({
          _id: { $in: itemIds },
          ownerId,
        }).lean()
      : [];
    const idToItem = Object.fromEntries(
      items.map((it) => [it._id.toString(), it])
    );

    for (const ms of mealSlots) {
      const slotKey = ms.slot || "meal";
      const lineItems = [];
      for (const si of ms.items || []) {
        const it = idToItem[si.itemId?.toString()];
        const qty = si.quantity ?? 1;
        const unitPrice = it?.unitPrice ?? 0;
        const lineTotal = qty * unitPrice;
        subtotal += lineTotal;
        lineItems.push({
          name: it?.name || "Item",
          quantity: qty,
          unitPrice,
          total: lineTotal,
          unit: it?.unit || "unit",
        });
      }
      if (lineItems.length) addDelivery(slotKey, lineItems);
    }
  }

  const deliveries = [...slotToDelivery.values()].map((d) => ({
    slot: d.slot,
    items: d.items,
    slotTotal: d.items.reduce((sum, i) => sum + (i.total || 0), 0),
  }));

  const tax = 0;
  const grandTotal = subtotal + tax;

  const paidAgg = await Payment.aggregate([
    {
      $match: {
        ownerId: new mongoose.Types.ObjectId(ownerId),
        customerId,
        status: "captured",
        paymentDate: { $gte: dayStart, $lt: dayEnd },
      },
    },
    { $group: { _id: null, total: { $sum: "$amount" } } },
  ]);
  const paidAmount = paidAgg[0]?.total ?? 0;

  const dueAmount = grandTotal - paidAmount;

  const runningAgg = await Invoice.aggregate([
    {
      $match: {
        ownerId: new mongoose.Types.ObjectId(ownerId),
        customerId,
        isVoid: { $ne: true },
        balanceDue: { $gt: 0 },
      },
    },
    { $group: { _id: null, total: { $sum: "$balanceDue" } } },
  ]);
  const runningBalance = runningAgg[0]?.total ?? 0;

  const paymentHistoryRows = await Payment.find({
    ownerId,
    customerId,
  })
    .sort({ paymentDate: -1 })
    .limit(5)
    .lean();
  const paymentHistory = paymentHistoryRows.map((p) => ({
    date: p.paymentDate,
    amount: p.amount ?? 0,
    method: p.paymentMethod ?? "",
    referenceId: p.transactionRef ?? "",
    status: p.status ?? "",
  }));

  const totalDeliveredItems = deliveries.reduce(
    (sum, slot) =>
      sum +
      slot.items.reduce((s, item) => s + (Number(item.quantity) || 0), 0),
    0
  );

  const receiptNumber = `RCP-${value.date.replace(/-/g, "")}-${customer._id.toString().slice(-4).toUpperCase()}`;

  const payload = {
    receipt: {
      receiptNumber,
      generatedAt: new Date().toISOString(),
      date: value.date,
    },
    vendor: {
      businessName: vendor.businessName || vendor.ownerName || "",
      phone: vendor.phone || "",
      email: vendor.email || "",
      address: vendor.address || "",
      gstin: vendor.gstin || "",
    },
    customer: {
      name: customer.name || "",
      phone: customer.phone || "",
      email: customer.email || "",
      address: customer.address || "",
      area: customer.area || "",
      customerCode:
        customer.customerCode || customer._id.toString().slice(-6).toUpperCase(),
    },
    subscription: {
      planName: subscription?.planId?.planName || "",
      planType: subscription?.planId?.planType || "",
      deliverySlot: subscription?.deliverySlot || "",
      deliveryDays: subscription?.deliveryDays || [],
      startDate: subscription?.startDate || null,
      endDate: subscription?.endDate || null,
    },
    deliveries,
    summary: {
      subtotal,
      taxRate: 0,
      taxAmount: tax,
      grandTotal,
      paidAmount,
      dueAmount,
      runningBalance,
      totalDeliveredItems,
    },
    paymentHistory,
    // Backward compatibility with current sheet data keys
    date: value.date,
    tax,
    subtotal,
    grandTotal,
    paidAmount,
    dueAmount,
    runningBalance,
  };

  const response = new ApiResponse(200, "Daily receipt fetched", payload);
  res.status(response.statusCode).json({
    success: response.success,
    message: response.message,
    data: response.data,
  });
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
