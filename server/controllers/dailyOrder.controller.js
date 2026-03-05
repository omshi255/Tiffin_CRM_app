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
import { sendNotification } from "../services/inAppNotification.service.js";

/**
 * Convert YYYY-MM-DD to UTC date
 */
const parseUTC = (d) => {
  const [y, m, day] = d.split("-").map(Number);
  return new Date(Date.UTC(y, m - 1, day));
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
 * DEBUG: fetch all orders for a subscription
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

  res.status(response.statusCode).json(response);
});

/**
 * POST /api/v1/daily-orders/generate
 */
export const generateOrders = asyncHandler(async (req, res) => {
  const ownerId = req.user.userId;
  const { date } = req.body;

  if (!date) {
    throw new ApiError(400, "date is required (YYYY-MM-DD)");
  }

  const targetDate = parseUTC(date);

  const { generatedCount, existingCount } = await generateDailyOrdersForDate(
    ownerId,
    targetDate
  );

  const response = new ApiResponse(200, "Orders generated", {
    generatedCount,
    existingCount,
    date,
  });

  res.status(response.statusCode).json(response);
});

/**
 * DEBUG: list subscriptions
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

  res.status(response.statusCode).json(response);
});

/**
 * DEBUG: find subscriptions matching a date
 */
export const debugMatchForDate = asyncHandler(async (req, res) => {
  const ownerId = req.user.userId;
  const { date } = req.query;

  if (!date) {
    throw new ApiError(400, "date query param required");
  }

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

  const response = new ApiResponse(200, "Debug match subscriptions", {
    date: day.toISOString(),
    dow,
    data: subs,
    total: subs.length,
  });

  res.status(response.statusCode).json(response);
});

/**
 * POST /api/v1/daily-orders/process
 */
export const processToday = asyncHandler(async (req, res) => {
  const ownerId = req.user.userId;
  const { date } = req.body;

  const targetDate = date
    ? parseUTC(date)
    : parseUTC(new Date().toISOString().slice(0, 10));

  const result = await DailyOrder.updateMany(
    {
      ownerId,
      orderDate: targetDate,
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
      orderDate: targetDate,
      status: "processing",
    })
      .select("customerId")
      .lean();

    const customerIds = [
      ...new Set(orders.map((o) => o.customerId.toString())),
    ];

    const customers = await Customer.find({
      _id: { $in: customerIds },
    })
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
        date: targetDate.toISOString().slice(0, 10),
      });
  }

  const response = new ApiResponse(200, "Orders processed", {
    processedCount,
  });

  res.status(response.statusCode).json(response);
});

/**
 * POST /api/v1/daily-orders/mark-delivered
 */
export const markDelivered = asyncHandler(async (req, res) => {
  const ownerId = req.user.userId;
  const { orderDate, customerId } = req.body;

  if (!orderDate) {
    throw new ApiError(400, "orderDate is required");
  }

  const date = parseUTC(orderDate);

  const filter = {
    ownerId,
    orderDate: date,
    status: { $in: ["pending", "processing"] },
  };

  if (customerId) {
    filter.customerId = customerId;
  }

  const orders = await DailyOrder.find(filter).select("_id customerId").lean();

  if (!orders.length) {
    const response = new ApiResponse(200, "No orders found to mark delivered", {
      deliveredCount: 0,
    });

    return res.status(response.statusCode).json(response);
  }

  const result = await DailyOrder.updateMany(filter, {
    $set: {
      status: "delivered",
      deliveredAt: new Date(),
    },
  });

  const deliveredCount = result.modifiedCount || 0;

  await Promise.all(
    orders.map((order) =>
      sendNotification({
        customerId: order.customerId,
        title: "Order delivered",
        message: "Your meal has been delivered",
        data: { orderId: order._id.toString() },
      })
    )
  );

  const response = new ApiResponse(200, "Orders marked as delivered", {
    deliveredCount,
    date: date.toISOString().slice(0, 10),
  });

  res.status(response.statusCode).json(response);
});

export const generateNextWeekOrders = asyncHandler(async (req, res) => {
  const ownerId = req.user.userId;

  const results = await generateOrdersForNextDays(ownerId, 7);

  const response = new ApiResponse(200, "Orders generated for next 7 days", {
    results,
  });

  res.status(response.statusCode).json(response);
});
