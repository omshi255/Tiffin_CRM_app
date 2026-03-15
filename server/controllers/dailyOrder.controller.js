import Joi from "joi";
import mongoose from "mongoose";
import DailyOrder from "../models/DailyOrder.model.js";
import Subscription from "../models/Subscription.model.js";
import Customer from "../models/Customer.model.js";
import User from "../models/User.model.js";
import DeliveryStaff from "../models/DeliveryStaff.model.js";
import { asyncHandler } from "../utils/asyncHandler.js";
import { ApiResponse } from "../class/apiResponseClass.js";
import { ApiError } from "../class/apiErrorClass.js";
import { sendToToken } from "../services/notification.service.js";
import {
  getTodayDailyOrders,
  generateDailyOrdersForDate,
  generateOrdersForNextDays,
} from "../services/dailyOrder.service.js";
import { sendNotification } from "../services/inAppNotification.service.js";
import { NOTIFICATION_TYPES } from "../utils/notificationTypes.js";

const parseUTC = (d) => {
  const [y, m, day] = d.split("-").map(Number);
  return new Date(Date.UTC(y, m - 1, day));
};

/**
 * Valid forward-only status transitions for an order.
 */
const VALID_TRANSITIONS = {
  out_for_delivery: ["pending", "processing"],
  delivered: ["pending", "processing", "out_for_delivery"],
};

/**
 * Deduct order.amount from Customer.balance within the given session.
 * Returns { newBalance, deducted } or throws ApiError on insufficient funds.
 */
const deductBalanceForOrder = async (order, vendorSettings, session) => {
  const orderAmount = order.amount || 0;
  if (orderAmount <= 0) return { newBalance: null, deducted: 0 };

  const allowNegative = vendorSettings?.allowNegativeBalance ?? false;

  const customer = await Customer.findById(order.customerId).session(session);
  if (!customer) throw new ApiError(404, "Customer not found");

  const newBalance = customer.balance - orderAmount;

  if (!allowNegative && newBalance < 0) {
    throw new ApiError(
      400,
      `Insufficient balance for customer "${customer.name}". Available: ₹${customer.balance}, Required: ₹${orderAmount}`
    );
  }

  await Customer.findByIdAndUpdate(
    order.customerId,
    { $inc: { balance: -orderAmount } },
    { session }
  );

  return { newBalance, deducted: orderAmount, customerId: customer._id };
};

/**
 * GET /api/v1/daily-orders/today
 */
export const getToday = asyncHandler(async (req, res) => {
  const ownerId = req.user.userId;
  const orders = await getTodayDailyOrders(ownerId);

  res.status(200).json(
    new ApiResponse(200, "Today's orders fetched", {
      data: orders,
      total: orders.length,
    })
  );
});

/**
 * POST /api/v1/daily-orders/process
 * Moves all pending orders to processing, notifies customers.
 */
export const processToday = asyncHandler(async (req, res) => {
  const ownerId = req.user.userId;
  const { date } = req.body;

  const targetDate = date
    ? parseUTC(date)
    : parseUTC(new Date().toISOString().slice(0, 10));

  const result = await DailyOrder.updateMany(
    { ownerId, orderDate: targetDate, status: "pending" },
    { $set: { status: "processing", processedAt: new Date() } }
  );

  const processedCount = result.modifiedCount || 0;

  if (processedCount > 0) {
    const orders = await DailyOrder.find({
      ownerId,
      orderDate: targetDate,
      status: "processing",
    })
      .select("customerId")
      .lean();

    const customerIds = [
      ...new Set(orders.map((o) => o.customerId.toString())),
    ];

    // Create in-app Notification doc + send FCM for each unique customer
    await Promise.all(
      customerIds.map((cid) =>
        sendNotification({
          customerId: cid,
          ownerId,
          type: NOTIFICATION_TYPES.ORDER_PROCESSING,
          title: "Tiffin Update 🍱",
          message: "Your tiffin is being prepared!",
          data: { screen: "orderDetail", status: "processing" },
        })
      )
    );
  }

  const io = req.app.get("io");
  if (io) {
    io.of("/delivery")
      .to(`admin:${ownerId}`)
      .emit("orders_processed", {
        count: processedCount,
        date: targetDate.toISOString().slice(0, 10),
      });
  }

  res.status(200).json(
    new ApiResponse(200, "Orders processed", { processedCount })
  );
});

/**
 * PATCH /api/v1/daily-orders/:id/status
 * Body: { status: 'out_for_delivery' | 'delivered' }
 *
 * Drives the order lifecycle:
 *   pending/processing → out_for_delivery  (notifies customer + vendor)
 *   pending/processing/out_for_delivery → delivered  (deducts balance + notifies)
 *
 * Vendor can update any of their orders.
 * Delivery staff (Day 3) will be restricted to their assigned orders.
 */
export const updateOrderStatus = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { status } = req.body;

  if (!status || !VALID_TRANSITIONS[status]) {
    throw new ApiError(
      400,
      `status must be one of: ${Object.keys(VALID_TRANSITIONS).join(", ")}`
    );
  }

  const role = req.user.role;
  const ownerId = req.user.ownerId || req.user.userId;

  // Delivery staff can only update orders assigned to them
  const orderFilter = { _id: id, ownerId };
  const order = await DailyOrder.findOne(orderFilter);
  if (!order) throw new ApiError(404, "Order not found");

  if (role === "delivery_staff") {
    const staffId = req.user.staffId;
    if (
      !order.deliveryStaffId ||
      order.deliveryStaffId.toString() !== staffId
    ) {
      throw new ApiError(403, "This order is not assigned to you");
    }
  }

  // Idempotent — already in target status
  if (order.status === status) {
    return res
      .status(200)
      .json(new ApiResponse(200, "Order already in this status", { order }));
  }

  if (!VALID_TRANSITIONS[status].includes(order.status)) {
    throw new ApiError(
      400,
      `Cannot move order from "${order.status}" to "${status}"`
    );
  }

  // ── out_for_delivery ──────────────────────────────────────────────
  if (status === "out_for_delivery") {
    order.status = "out_for_delivery";
    order.outForDeliveryAt = new Date();
    await order.save();

    await Promise.all([
      sendNotification({
        customerId: order.customerId,
        ownerId,
        type: NOTIFICATION_TYPES.OUT_FOR_DELIVERY,
        title: "Out for delivery! 🛵",
        message: "Your tiffin is on the way",
        data: { orderId: id, status: "out_for_delivery" },
      }),
      sendNotification({
        userId: ownerId,
        type: NOTIFICATION_TYPES.OUT_FOR_DELIVERY,
        title: "Order out for delivery",
        message: "An order is out for delivery",
        data: {
          orderId: id,
          customerId: order.customerId.toString(),
          status: "out_for_delivery",
        },
      }),
    ]);

    return res.status(200).json(
      new ApiResponse(200, "Order marked out for delivery", { order })
    );
  }

  // ── delivered ─────────────────────────────────────────────────────
  // ownerId is always the vendor's userId (set by RBAC for vendor, stored in JWT for delivery_staff)
  const vendor = await User.findById(ownerId).select("settings").lean();

  const session = await mongoose.startSession();
  session.startTransaction();

  try {
    const { newBalance, deducted } = await deductBalanceForOrder(
      order,
      vendor?.settings,
      session
    );

    order.status = "delivered";
    order.deliveredAt = new Date();
    await order.save({ session });

    await session.commitTransaction();
    session.endSession();

    const balanceMsg =
      newBalance !== null ? ` Wallet balance: ₹${newBalance}` : "";

    await Promise.all([
      sendNotification({
        customerId: order.customerId,
        ownerId,
        type: NOTIFICATION_TYPES.DELIVERED,
        title: "Tiffin delivered! ✅",
        message: `Your meal has been delivered.${balanceMsg}`,
        data: { orderId: id, status: "delivered", newBalance },
      }),
      sendNotification({
        userId: ownerId,
        type: NOTIFICATION_TYPES.DELIVERED,
        title: "Order delivered",
        message: "An order has been successfully delivered",
        data: {
          orderId: id,
          customerId: order.customerId.toString(),
          status: "delivered",
        },
      }),
    ]);

    // Low balance alert
    if (newBalance !== null) {
      const threshold = vendor?.settings?.lowBalanceThreshold ?? 100;
      if (newBalance < threshold) {
        const customerDoc = await Customer.findById(order.customerId)
          .select("name")
          .lean();
        await Promise.all([
          sendNotification({
            customerId: order.customerId,
            ownerId,
            type: NOTIFICATION_TYPES.LOW_BALANCE,
            title: "Low balance alert ⚠️",
            message: `₹${newBalance.toFixed(2)} remaining. Please recharge.`,
            data: { balance: newBalance, screen: "wallet" },
          }),
          sendNotification({
            userId: ownerId,
            type: NOTIFICATION_TYPES.LOW_BALANCE,
            title: "Customer low balance",
            message: `${customerDoc?.name || "A customer"} has low balance (₹${newBalance.toFixed(2)})`,
            data: {
              customerId: order.customerId.toString(),
              balance: newBalance,
            },
          }),
        ]);
      }
    }

    return res.status(200).json(
      new ApiResponse(200, "Order marked delivered", {
        order,
        balanceDeducted: deducted,
        customerNewBalance: newBalance,
      })
    );
  } catch (err) {
    if (session.inTransaction()) {
      await session.abortTransaction();
    }
    session.endSession();
    throw err;
  }
});

/**
 * POST /api/v1/daily-orders/mark-delivered
 * Legacy bulk endpoint — marks all matching orders as delivered and deducts balance.
 * Prefer PATCH /:id/status for single-order flow (used by delivery boy).
 */
export const markDelivered = asyncHandler(async (req, res) => {
  const ownerId = req.user.userId;
  const { orderDate, customerId } = req.body;

  if (!orderDate) throw new ApiError(400, "orderDate is required");

  const date = parseUTC(orderDate);

  const filter = {
    ownerId,
    orderDate: date,
    status: { $in: ["pending", "processing", "out_for_delivery"] },
  };
  if (customerId) filter.customerId = customerId;

  const orders = await DailyOrder.find(filter)
    .select("_id customerId amount status")
    .lean();

  if (!orders.length) {
    return res.status(200).json(
      new ApiResponse(200, "No orders to deliver", { deliveredCount: 0 })
    );
  }

  const vendor = await User.findById(ownerId).select("settings").lean();
  const allowNegative = vendor?.settings?.allowNegativeBalance ?? false;

  // Aggregate total deduction per customer
  const deductionMap = {};
  for (const o of orders) {
    const cid = o.customerId.toString();
    deductionMap[cid] = (deductionMap[cid] || 0) + (o.amount || 0);
  }

  const session = await mongoose.startSession();
  session.startTransaction();

  // Track new balances per customer to fire low-balance alerts after commit
  const newBalanceMap = {};

  try {
    // Update all orders to delivered
    await DailyOrder.updateMany(
      { _id: { $in: orders.map((o) => o._id) } },
      { $set: { status: "delivered", deliveredAt: new Date() } },
      { session }
    );

    // Deduct balance per customer
    for (const [cid, totalDeduction] of Object.entries(deductionMap)) {
      if (totalDeduction <= 0) continue;

      const customer = await Customer.findById(cid).session(session);
      if (!customer) continue;

      const newBalance = customer.balance - totalDeduction;
      if (!allowNegative && newBalance < 0) {
        // Skip deduction for this customer (don't block the whole batch)
        continue;
      }

      await Customer.findByIdAndUpdate(
        cid,
        { $inc: { balance: -totalDeduction } },
        { session }
      );

      newBalanceMap[cid] = { newBalance, name: customer.name };
    }

    await session.commitTransaction();
    session.endSession();
  } catch (err) {
    await session.abortTransaction();
    session.endSession();
    throw err;
  }

  const threshold = vendor?.settings?.lowBalanceThreshold ?? 100;

  // Send delivery + low-balance notifications after transaction
  await Promise.all(
    orders.map((order) =>
      sendNotification({
        customerId: order.customerId,
        ownerId,
        type: NOTIFICATION_TYPES.DELIVERED,
        title: "Tiffin delivered! ✅",
        message: "Your meal has been delivered",
        data: { orderId: order._id.toString(), status: "delivered" },
      })
    )
  );

  // Low balance alerts for customers whose balance dropped below threshold
  const lowBalanceCustomers = Object.entries(newBalanceMap).filter(
    ([, { newBalance }]) => newBalance < threshold
  );

  await Promise.all(
    lowBalanceCustomers.flatMap(([cid, { newBalance, name }]) => [
      sendNotification({
        customerId: cid,
        ownerId,
        type: NOTIFICATION_TYPES.LOW_BALANCE,
        title: "Low balance alert ⚠️",
        message: `₹${newBalance.toFixed(2)} remaining. Please recharge.`,
        data: { balance: newBalance, screen: "wallet" },
      }),
      sendNotification({
        userId: ownerId,
        type: NOTIFICATION_TYPES.LOW_BALANCE,
        title: "Customer low balance",
        message: `${name || "A customer"} has low balance (₹${newBalance.toFixed(2)})`,
        data: { customerId: cid, balance: newBalance },
      }),
    ])
  );

  res.status(200).json(
    new ApiResponse(200, "Orders marked as delivered", {
      deliveredCount: orders.length,
      date: date.toISOString().slice(0, 10),
    })
  );
});

/**
 * POST /api/v1/daily-orders/generate
 */
export const generateOrders = asyncHandler(async (req, res) => {
  const ownerId = req.user.userId;
  const { date } = req.body;

  if (!date) throw new ApiError(400, "date is required (YYYY-MM-DD)");

  const targetDate = parseUTC(date);
  const { generatedCount, existingCount } = await generateDailyOrdersForDate(
    ownerId,
    targetDate
  );

  res.status(200).json(
    new ApiResponse(200, "Orders generated", { generatedCount, existingCount, date })
  );
});

/**
 * POST /api/v1/daily-orders/generate-week
 */
export const generateNextWeekOrders = asyncHandler(async (req, res) => {
  const ownerId = req.user.userId;
  const results = await generateOrdersForNextDays(ownerId, 7);

  res.status(200).json(
    new ApiResponse(200, "Orders generated for next 7 days", { results })
  );
});

/**
 * DEBUG: list all subscriptions for this vendor
 */
export const debugSubscriptions = asyncHandler(async (req, res) => {
  const ownerId = req.user.userId;

  const subs = await Subscription.find({ ownerId })
    .populate("customerId", "name phone")
    .populate("planId", "planName price")
    .lean();

  res.status(200).json(
    new ApiResponse(200, "Debug subscriptions", { data: subs, total: subs.length })
  );
});

/**
 * DEBUG: fetch all orders for a subscription
 */
export const debugOrders = asyncHandler(async (req, res) => {
  const ownerId = req.user.userId;
  const { subscriptionId } = req.params;

  const orders = await DailyOrder.find({ ownerId, subscriptionId })
    .populate("customerId", "name phone")
    .populate("planId", "planName price")
    .sort({ orderDate: 1 })
    .lean();

  res.status(200).json(
    new ApiResponse(200, "Debug orders fetched", {
      data: orders,
      total: orders.length,
      TODAY: new Date().toISOString().slice(0, 10),
    })
  );
});

/**
 * PATCH /api/v1/daily-orders/:id/assign
 * Vendor assigns a delivery staff member to one order.
 * Body: { deliveryStaffId }
 */
export const assignDeliveryStaff = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { deliveryStaffId } = req.body;

  if (!deliveryStaffId || !mongoose.Types.ObjectId.isValid(deliveryStaffId)) {
    throw new ApiError(400, "deliveryStaffId is required");
  }

  const ownerId = req.user.userId;

  const [order, staff] = await Promise.all([
    DailyOrder.findOne({ _id: id, ownerId }),
    DeliveryStaff.findOne({ _id: deliveryStaffId, ownerId, isActive: true }),
  ]);

  if (!order) throw new ApiError(404, "Order not found");
  if (!staff) throw new ApiError(404, "Delivery staff not found or inactive");

  if (["delivered", "cancelled", "failed"].includes(order.status)) {
    throw new ApiError(400, `Cannot assign staff to an order with status "${order.status}"`);
  }

  order.deliveryStaffId = deliveryStaffId;
  await order.save();

  // Notify delivery staff — use linked userId (User.fcmToken) if available,
  // fall back to direct FCM to staff.fcmToken on DeliveryStaff record
  if (staff.userId) {
    await sendNotification({
      userId: staff.userId.toString(),
      type: NOTIFICATION_TYPES.TASK_ASSIGNED,
      title: "New delivery assigned 🛵",
      message: "You have a new delivery task today",
      data: { orderId: id, screen: "myDeliveries" },
    }).catch(() => {});
  } else if (staff.fcmToken) {
    await sendToToken(
      staff.fcmToken,
      "New delivery assigned 🛵",
      "You have a new delivery task today",
      { orderId: id, screen: "myDeliveries" }
    ).catch(() => {});
  }

  const updated = await DailyOrder.findById(id)
    .populate("customerId", "name phone address area")
    .populate("deliveryStaffId", "name phone")
    .lean();

  res.status(200).json(new ApiResponse(200, "Delivery staff assigned", updated));
});

/**
 * POST /api/v1/daily-orders/assign-bulk
 * Vendor assigns one delivery staff to multiple orders.
 * Body: { orderIds: [], deliveryStaffId }
 */
export const assignBulk = asyncHandler(async (req, res) => {
  const { orderIds, deliveryStaffId } = req.body;

  if (!Array.isArray(orderIds) || orderIds.length === 0) {
    throw new ApiError(400, "orderIds must be a non-empty array");
  }
  if (!deliveryStaffId || !mongoose.Types.ObjectId.isValid(deliveryStaffId)) {
    throw new ApiError(400, "deliveryStaffId is required");
  }

  const ownerId = req.user.userId;

  const staff = await DeliveryStaff.findOne({
    _id: deliveryStaffId,
    ownerId,
    isActive: true,
  });
  if (!staff) throw new ApiError(404, "Delivery staff not found or inactive");

  const result = await DailyOrder.updateMany(
    {
      _id: { $in: orderIds },
      ownerId,
      status: { $nin: ["delivered", "cancelled", "failed"] },
    },
    { $set: { deliveryStaffId } }
  );

  // Notify delivery staff once for the batch
  if (result.modifiedCount > 0) {
    const msg = `You have ${result.modifiedCount} delivery task(s) today`;
    if (staff.userId) {
      await sendNotification({
        userId: staff.userId.toString(),
        type: NOTIFICATION_TYPES.TASK_ASSIGNED,
        title: "New deliveries assigned 🛵",
        message: msg,
        data: { screen: "myDeliveries", count: result.modifiedCount },
      }).catch(() => {});
    } else if (staff.fcmToken) {
      await sendToToken(staff.fcmToken, "New deliveries assigned 🛵", msg, {
        screen: "myDeliveries",
        count: result.modifiedCount,
      }).catch(() => {});
    }
  }

  res.status(200).json(
    new ApiResponse(200, "Bulk assignment complete", {
      assignedCount: result.modifiedCount,
      deliveryStaffId,
      staffName: staff.name,
    })
  );
});

/**
 * POST /api/v1/daily-orders/:id/accept
 * Delivery staff accepts their assigned task.
 */
export const acceptTask = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const staffId = req.user.staffId;
  const ownerId = req.user.ownerId;

  if (!staffId) throw new ApiError(403, "Staff ID not found in token");

  const order = await DailyOrder.findOne({ _id: id, ownerId })
    .populate("customerId", "name phone")
    .lean();

  if (!order) throw new ApiError(404, "Order not found");

  if (!order.deliveryStaffId || order.deliveryStaffId.toString() !== staffId) {
    throw new ApiError(403, "This order is not assigned to you");
  }

  if (["delivered", "cancelled", "failed"].includes(order.status)) {
    throw new ApiError(400, `Cannot accept an order with status "${order.status}"`);
  }

  await DailyOrder.findByIdAndUpdate(id, { $set: { acceptedAt: new Date() } });

  await sendNotification({
    userId: ownerId,
    type: NOTIFICATION_TYPES.TASK_ACCEPTED,
    title: "Delivery accepted ✅",
    message: `Delivery for ${order.customerId?.name || "customer"} was accepted`,
    data: { orderId: id, action: "accepted" },
  });

  res.status(200).json(new ApiResponse(200, "Task accepted", { orderId: id }));
});

/**
 * POST /api/v1/daily-orders/:id/reject
 * Delivery staff rejects their assigned task.
 * Body: { reason? }
 * Clears deliveryStaffId; resets status to 'processing'; notifies vendor.
 */
export const rejectTask = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { reason } = req.body || {};
  const staffId = req.user.staffId;
  const ownerId = req.user.ownerId;

  if (!staffId) throw new ApiError(403, "Staff ID not found in token");

  const order = await DailyOrder.findOne({ _id: id, ownerId })
    .populate("customerId", "name phone")
    .lean();

  if (!order) throw new ApiError(404, "Order not found");

  if (!order.deliveryStaffId || order.deliveryStaffId.toString() !== staffId) {
    throw new ApiError(403, "This order is not assigned to you");
  }

  if (["delivered", "cancelled", "failed"].includes(order.status)) {
    throw new ApiError(400, `Cannot reject an order with status "${order.status}"`);
  }

  // Look up staff name for notification
  const staff = await DeliveryStaff.findById(staffId).select("name").lean();

  await DailyOrder.findByIdAndUpdate(id, {
    $set: {
      deliveryStaffId: null,
      acceptedAt: null,
      status: "processing",
    },
  });

  await sendNotification({
    userId: ownerId,
    type: NOTIFICATION_TYPES.TASK_REJECTED,
    title: "⚠️ Delivery rejected",
    message: `${staff?.name || "Delivery boy"} rejected delivery for ${order.customerId?.name || "customer"}. Please reassign.`,
    data: { orderId: id, action: "rejected", reason: reason || "" },
  });

  res.status(200).json(
    new ApiResponse(200, "Task rejected — please reassign", { orderId: id })
  );
});

/**
 * PATCH /api/v1/daily-orders/:id/quantities   (customer role)
 * Body: [{ itemId, quantity }]
 * Rules: only existing item IDs, quantity ≥ 1, cannot add or remove items.
 * Recalculates DailyOrder.amount.
 */
const quantitiesSchema = Joi.array()
  .items(
    Joi.object({
      itemId: Joi.string().hex().length(24).required().messages({
        "string.length": "itemId must be a 24-character hex string",
        "string.pattern.base": "itemId must be a valid ObjectId",
      }),
      quantity: Joi.number().integer().min(1).required().messages({
        "number.min": "quantity must be at least 1",
        "number.base": "quantity must be a number",
      }),
    })
  )
  .min(1)
  .required();

export const updateOrderQuantities = asyncHandler(async (req, res) => {
  const { id } = req.params;
  const { customerId } = req.user;

  if (!customerId) throw new ApiError(403, "Customer ID not found in token");

  const { error, value } = quantitiesSchema.validate(req.body, {
    abortEarly: false,
  });
  if (error) {
    throw new ApiError(400, error.details.map((d) => d.message).join("; "));
  }

  const order = await DailyOrder.findOne({ _id: id, customerId });
  if (!order) throw new ApiError(404, "Order not found");

  if (["delivered", "cancelled", "failed", "skipped"].includes(order.status)) {
    throw new ApiError(
      400,
      `Cannot update quantities on a ${order.status} order`
    );
  }

  // Validate: only existing itemIds allowed — no add/remove
  const existingItemIds = new Set(
    order.resolvedItems.map((i) => i.itemId.toString())
  );
  for (const { itemId } of value) {
    if (!existingItemIds.has(itemId)) {
      throw new ApiError(
        400,
        `Item ${itemId} is not part of this order. You can only adjust quantities of existing items.`
      );
    }
  }

  // Build qty map and apply
  const qtyMap = Object.fromEntries(value.map(({ itemId, quantity }) => [itemId, quantity]));

  let newAmount = 0;
  const updatedItems = order.resolvedItems.map((item) => {
    const newQty = qtyMap[item.itemId.toString()] ?? item.quantity;
    const subtotal = newQty * item.unitPrice;
    newAmount += subtotal;
    return {
      itemId: item.itemId,
      itemName: item.itemName,
      quantity: newQty,
      unitPrice: item.unitPrice,
      subtotal,
    };
  });

  order.resolvedItems = updatedItems;
  order.amount = newAmount;
  await order.save();

  res.status(200).json(
    new ApiResponse(200, "Order quantities updated", {
      orderId: id,
      resolvedItems: order.resolvedItems,
      amount: newAmount,
    })
  );
});

/**
 * DEBUG: find subscriptions matching a specific date
 */
export const debugMatchForDate = asyncHandler(async (req, res) => {
  const ownerId = req.user.userId;
  const { date } = req.query;

  if (!date) throw new ApiError(400, "date query param required");

  const day = parseUTC(date);
  const dow = day.getUTCDay();

  const subs = await Subscription.find({
    ownerId,
    status: "active",
    startDate: { $lte: day },
    endDate: { $gte: day },
    deliveryDays: { $in: [dow] },
  })
    .populate("customerId", "name phone")
    .populate("planId", "planName price")
    .lean();

  res.status(200).json(
    new ApiResponse(200, "Debug match subscriptions", {
      date: day.toISOString(),
      dow,
      data: subs,
      total: subs.length,
    })
  );
});
