import Subscription from "../models/Subscription.model.js";
import Payment from "../models/Payment.model.js";
import DailyOrder from "../models/DailyOrder.model.js";

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

export const getSummaryReport = async (period = "monthly") => {
  const { start, end } = getDateRange(period);

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
};
