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
 * Scoped by ownerId. When ownerId is null (admin), aggregates system-wide.
 */
export const getSummaryReport = async (ownerId, period = "monthly") => {
  const { start, end } = getDateRange(period);

  if (ownerId == null) {
    const [activeSubscriptions, revenue, deliveries] = await Promise.all([
      Subscription.countDocuments({ status: "active" }),
      Payment.aggregate([
        {
          $match: {
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
  }

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

  const filter = {
    orderDate: { $gte: today, $lt: tomorrow },
  };
  if (ownerId != null) filter.ownerId = ownerId;

  const orders = await DailyOrder.find(filter)
    .populate("customerId", "name phone address area")
    .populate("deliveryStaffId", "name phone")
    .populate("ownerId", "businessName ownerName phone")
    .select(
      "status customerId deliveryStaffId ownerId deliverySlot mealType amount orderDate"
    )
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

  const subFilter = {
    status: "active",
    endDate: { $gte: today, $lte: future },
  };
  if (ownerId != null) subFilter.ownerId = ownerId;

  const subscriptions = await Subscription.find(subFilter)
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
  const invoiceFilter = {
    paymentStatus: { $in: ["unpaid", "partial"] },
    isVoid: { $ne: true },
  };
  if (ownerId != null) invoiceFilter.ownerId = ownerId;

  const customerFilter = {
    $or: [{ walletBalance: { $lt: 0 } }, { balance: { $lt: 0 } }],
    isDeleted: { $ne: true },
  };
  if (ownerId != null) customerFilter.ownerId = ownerId;

  const [unpaidInvoices, negativeBalanceCustomers] = await Promise.all([
    Invoice.find(invoiceFilter)
      .populate("customerId", "name phone")
      .populate("ownerId", "businessName ownerName phone")
      .sort({ createdAt: -1 })
      .lean(),

    Customer.find(customerFilter)
      .select("name phone walletBalance balance address ownerId")
      .populate("ownerId", "businessName ownerName phone")
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
