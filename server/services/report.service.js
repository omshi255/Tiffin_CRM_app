import mongoose from "mongoose";
import Subscription from "../models/Subscription.model.js";
import Payment from "../models/Payment.model.js";
import DailyOrder from "../models/DailyOrder.model.js";
import Invoice from "../models/Invoice.model.js";
import Customer from "../models/Customer.model.js";

const getDateRange = (period) => {
  const now = new Date();
  const start = new Date();

  if (period === "daily") {
    start.setHours(0, 0, 0, 0);
  } else if (period === "weekly") {
    start.setDate(now.getDate() - 7);
  } else if (period === "monthly") {
    start.setMonth(now.getMonth() - 1);
  } else {
    throw new Error("Invalid period. Use daily, weekly, or monthly.");
  }

  return { start, end: now };
};

/**
 * Summary: active subs + revenue (captured payments) + delivered orders.
 * Scoped by ownerId.
 */
export const getSummaryReport = async (ownerId, period = "monthly") => {
  const { start, end } = getDateRange(period);
  const ownerOid = new mongoose.Types.ObjectId(ownerId);

  const [activeSubscriptions, revenue, deliveries] = await Promise.all([
    Subscription.countDocuments({ ownerId, status: "active" }),

    Payment.aggregate([
      {
        $match: {
          ownerId: ownerOid,
          status: "captured",
          createdAt: { $gte: start, $lte: end },
        },
      },
      {
        $group: {
          _id: null,
          totalRevenue: { $sum: "$amount" },
        },
      },
    ]),

    DailyOrder.countDocuments({
      ownerId,
      orderDate: { $gte: start, $lte: end },
      status: "delivered",
    }),
  ]);

  return {
    activeSubscriptions,
    revenue: revenue[0]?.totalRevenue || 0,
    deliveries,
    period,
  };
};

/**
 * Today's delivery orders grouped by status.
 */
export const getTodayDeliveriesReport = async (ownerId) => {
  const today = new Date();
  today.setUTCHours(0, 0, 0, 0);
  const tomorrow = new Date(today);
  tomorrow.setUTCDate(tomorrow.getUTCDate() + 1);

  const orders = await DailyOrder.find({
    ownerId,
    orderDate: { $gte: today, $lt: tomorrow },
  })
    .populate("customerId", "name phone address area")
    .populate("deliveryStaffId", "name phone")
    .select("status customerId deliveryStaffId deliverySlot mealType amount orderDate")
    .lean();

  const grouped = {};
  for (const order of orders) {
    const s = order.status;
    if (!grouped[s]) grouped[s] = [];
    grouped[s].push(order);
  }

  const summary = {};
  for (const [status, list] of Object.entries(grouped)) {
    summary[status] = list.length;
  }

  return {
    date: today.toISOString().slice(0, 10),
    total: orders.length,
    summary,
    orders,
  };
};

/**
 * Active subscriptions expiring within the next N days.
 */
export const getExpiringSubscriptionsReport = async (ownerId, days = 7) => {
  const today = new Date();
  today.setUTCHours(0, 0, 0, 0);
  const future = new Date(today);
  future.setUTCDate(future.getUTCDate() + parseInt(days, 10));

  const subscriptions = await Subscription.find({
    ownerId,
    status: "active",
    endDate: { $gte: today, $lte: future },
  })
    .populate("customerId", "name phone address")
    .populate("planId", "planName price")
    .sort({ endDate: 1 })
    .lean();

  return {
    days: parseInt(days, 10),
    total: subscriptions.length,
    subscriptions,
  };
};

/**
 * Invoices with unpaid/partial status OR customers with negative wallet balance.
 */
export const getPendingPaymentsReport = async (ownerId) => {
  const [unpaidInvoices, negativeBalanceCustomers] = await Promise.all([
    Invoice.find({
      ownerId,
      paymentStatus: { $in: ["unpaid", "partial"] },
      isVoid: { $ne: true },
    })
      .populate("customerId", "name phone")
      .sort({ createdAt: -1 })
      .lean(),

    Customer.find({
      ownerId,
      balance: { $lt: 0 },
      isDeleted: { $ne: true },
    })
      .select("name phone balance address")
      .lean(),
  ]);

  return {
    unpaidInvoices: {
      total: unpaidInvoices.length,
      items: unpaidInvoices,
    },
    negativeBalanceCustomers: {
      total: negativeBalanceCustomers.length,
      items: negativeBalanceCustomers,
    },
  };
};
