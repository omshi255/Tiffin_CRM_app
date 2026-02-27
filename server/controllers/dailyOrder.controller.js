import DailyOrder from "../models/DailyOrder.model.js";
import Subscription from "../models/Subscription.model.js";
import { asyncHandler } from "../utils/asyncHandler.js";
import { ApiResponse } from "../class/apiResponseClass.js";
import { ApiError } from "../class/apiErrorClass.js";
import { sendToToken } from "../services/notification.service.js";
import Customer from "../models/Customer.model.js";
import {
  getTodayDailyOrders,
  generateDailyOrdersForDate,
} from "../services/dailyOrder.service.js";

const startOfDay = (d) => {
  const date = new Date(d);
  date.setHours(0, 0, 0, 0);
  return date;
};

/**
 * GET /api/v1/daily-orders/today
 */
export const getToday = asyncHandler(async (req, res) => {
  const ownerId = req.user.userId;
  const orders = await getTodayDailyOrders(ownerId);

  const response = new ApiResponse(200, "Today's orders fetched", {
    data: orders,
    total: orders.length,
  });

  res.status(response.statusCode).json({
    success: response.success,
    message: response.message,
    data: response.data,
  });
});

/**
 * GET /api/v1/daily-orders/debug/subscription/:subscriptionId
 * Debug: fetch all orders for a subscription (not just today)
 */
export const debugOrders = asyncHandler(async (req, res) => {
  const ownerId = req.user.userId;
  const { subscriptionId } = req.params;

  const orders = await DailyOrder.find({
    ownerId,
    subscriptionId,
  })
    .populate("customerId", "name phone")
    .populate("planId", "planName price")
    .sort({ orderDate: 1 })
    .lean();

  const response = new ApiResponse(200, "Debug orders fetched", {
    data: orders,
    total: orders.length,
    TODAY: new Date().toISOString().slice(0, 10),
  });

  res.status(response.statusCode).json({
    success: response.success,
    message: response.message,
    data: response.data,
  });
});

/**
 * POST /api/v1/daily-orders/generate
 * Manually regenerate orders for a given date
 * Body: { date: "2026-02-27", subscriptionId?: "..." }
 */
export const generateOrders = asyncHandler(async (req, res) => {
  const ownerId = req.user.userId;
  const { date } = req.body;

  if (!date) {
    throw new ApiError(400, "date is required (format: YYYY-MM-DD)");
  }

  const targetDate = new Date(date);
  const { generatedCount, existingCount } = await generateDailyOrdersForDate(
    ownerId,
    targetDate
  );

  const response = new ApiResponse(200, "Orders generated", {
    generatedCount,
    existingCount,
    date: date,
    ownerId,
  });

  res.status(response.statusCode).json({
    success: response.success,
    message: response.message,
    data: response.data,
  });
});

/**
 * GET /api/v1/daily-orders/debug/subscriptions
 * Debug: list all subscriptions for this owner
 */
export const debugSubscriptions = asyncHandler(async (req, res) => {
  const ownerId = req.user.userId;

  const subs = await Subscription.find({ ownerId })
    .populate("customerId", "name phone")
    .populate("planId", "planName price")
    .lean();

  const response = new ApiResponse(200, "Debug subscriptions", {
    data: subs,
    total: subs.length,
  });

  res.status(response.statusCode).json({
    success: response.success,
    message: response.message,
    data: response.data,
  });
});

/**
 * GET /api/v1/daily-orders/debug/match
 * Query: date=YYYY-MM-DD
 * Returns subscriptions matching the date filter used by generator
 */
export const debugMatchForDate = asyncHandler(async (req, res) => {
  const ownerId = req.user.userId;
  const { date } = req.query;
  if (!date) {
    throw new ApiError(400, "date query param required");
  }

  // parse date string as UTC midnight to avoid timezone shift
  const day = new Date(
    Date.UTC(...date.split("-").map((n) => parseInt(n, 10)))
  );
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

  const response = new ApiResponse(200, "Debug match subscriptions", {
    date: day.toISOString(),
    dow,
    data: subs,
    total: subs.length,
  });

  res.status(response.statusCode).json({
    success: response.success,
    message: response.message,
    data: response.data,
  });
});

/**
 * POST /api/v1/daily-orders/process
 * BR-01/BR-03 core: bulk update pending -> processing and send FCM.
 */
export const processToday = asyncHandler(async (req, res) => {
  const ownerId = req.user.userId;
  const today = startOfDay(new Date());

  const result = await DailyOrder.updateMany(
    {
      ownerId,
      orderDate: today,
      status: "pending",
    },
    {
      $set: {
        status: "processing",
        processedAt: new Date(),
      },
    }
  );

  const processedCount = result.modifiedCount || 0;

  if (processedCount > 0) {
    const orders = await DailyOrder.find({
      ownerId,
      orderDate: today,
      status: "processing",
    })
      .select("customerId")
      .lean();

    const customerIds = [
      ...new Set(orders.map((o) => o.customerId.toString())),
    ];
    const customers = await Customer.find({ _id: { $in: customerIds } })
      .select("fcmToken")
      .lean();

    for (const c of customers) {
      if (c.fcmToken) {
        await sendToToken(
          c.fcmToken,
          "Tiffin Update",
          "Your tiffin is being prepared!",
          { screen: "orderDetail" }
        );
      }
    }
  }

  const io = req.app.get("io");
  if (io) {
    io.of("/delivery")
      .to(`admin:${ownerId}`)
      .emit("orders_processed", {
        count: processedCount,
        date: today.toISOString().slice(0, 10),
      });
  }

  const response = new ApiResponse(200, "Orders processed", {
    processedCount,
  });

  res.status(response.statusCode).json({
    success: response.success,
    message: response.message,
    data: response.data,
  });
});

/**
 * POST /api/v1/daily-orders/mark-delivered
 * Bulk mark orders as delivered for a specific date
 * Body: { orderDate: "2026-03-01", customerId?: "...", status: "delivered" }
 */
export const markDelivered = asyncHandler(async (req, res) => {
  const ownerId = req.user.userId;
  const { orderDate, customerId } = req.body;

  if (!orderDate) {
    throw new ApiError(400, "orderDate is required");
  }

  const date = startOfDay(new Date(orderDate));

  const filter = {
    ownerId,
    orderDate: date,
    status: { $in: ["pending", "processing"] }, // can mark from pending or processing
  };

  if (customerId) {
    filter.customerId = customerId;
  }

  const result = await DailyOrder.updateMany(filter, {
    $set: {
      status: "delivered",
      deliveredAt: new Date(),
    },
  });

  const deliveredCount = result.modifiedCount || 0;

  const response = new ApiResponse(200, "Orders marked as delivered", {
    deliveredCount,
    date: date.toISOString().slice(0, 10),
  });

  res.status(response.statusCode).json({
    success: response.success,
    message: response.message,
    data: response.data,
  });
});
