import Delivery from "../models/Delivery.model.js";
import Subscription from "../models/Subscription.model.js";

/**
 * Get start of day in local time (UTC midnight or configurable)
 * @param {Date} d
 * @returns {Date}
 */
const startOfDay = (d) => {
  const date = new Date(d);
  date.setHours(0, 0, 0, 0);
  return date;
};

/**
 * Get end of day (23:59:59.999)
 * @param {Date} d
 * @returns {Date}
 */
const endOfDay = (d) => {
  const date = new Date(d);
  date.setUTCHours(23, 59, 59, 999);
  return date;
};

/**
 * Find active subscriptions for a given date.
 * A subscription is active for date D if startDate <= D <= endDate and status === 'active'.
 */
const getActiveSubscriptionsForDate = async (date) => {
  const dayStart = startOfDay(date);
  const dayEnd = endOfDay(date);

  return Subscription.find({
    status: "active",
    startDate: { $lte: dayEnd },
    endDate: { $gte: dayStart },
  })
    .populate("customerId", "name phone address location")
    .lean();
};

/**
 * Ensure Delivery records exist for all active subscriptions for today.
 * Creates missing ones; returns all deliveries for the date.
 * @param {Date} [date] - defaults to today
 * @returns {Promise<Array>} deliveries with customer/address populated
 */
export const getTodaysDeliveries = async (date = new Date()) => {
  const dayStart = startOfDay(date);

  const activeSubs = await getActiveSubscriptionsForDate(date);
  const existingDeliveries = await Delivery.find({ date: dayStart })
    .populate("customerId", "name phone address location")
    .populate("subscriptionId", "planId")
    .populate("deliveryBoyId", "name phone")
    .lean();

  const existingSubIds = new Set(
    existingDeliveries.map((d) => {
      const sid = d.subscriptionId;
      return (sid?._id || sid)?.toString();
    })
  );

  const toCreate = [];
  for (const sub of activeSubs) {
    const subId = sub._id.toString();
    if (!existingSubIds.has(subId)) {
      toCreate.push({
        customerId: sub.customerId?._id || sub.customerId,
        subscriptionId: sub._id,
        date: dayStart,
        status: "pending",
      });
    }
  }

  if (toCreate.length > 0) {
    await Delivery.insertMany(toCreate);
  }

  const allDeliveries = await Delivery.find({ date: dayStart })
    .populate("customerId", "name phone address location")
    .populate("subscriptionId", "planId")
    .populate("deliveryBoyId", "name phone")
    .sort({ createdAt: 1 })
    .lean();

  return allDeliveries;
};
