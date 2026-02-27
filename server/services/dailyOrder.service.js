import DailyOrder from "../models/DailyOrder.model.js";
import Subscription from "../models/Subscription.model.js";
import MealPlan from "../models/Plan.model.js";

const startOfDay = (d) => {
  const date = new Date(d);
  date.setHours(0, 0, 0, 0);
  return date;
};

// parse a YYYY-MM-DD string as a UTC date (midnight UTC)
const parseUTC = (d) => {
  if (!d) return new Date();
  // if already a Date, return a copy with UTC midnight
  if (d instanceof Date) {
    const date = new Date(d);
    date.setUTCHours(0, 0, 0, 0);
    return date;
  }
  const parts = String(d)
    .split("-")
    .map((x) => parseInt(x, 10));
  if (parts.length === 3) {
    const [y, m, day] = parts;
    return new Date(Date.UTC(y, m - 1, day));
  }
  // fallback to default constructor
  const date = new Date(d);
  date.setUTCHours(0, 0, 0, 0);
  return date;
};

/**
 * Generate DailyOrder records for a given date and owner.
 * Used by POST /subscriptions (BR-03) and midnight cron.
 */
export const generateDailyOrdersForDate = async (ownerId, date) => {
  // date may be a string (YYYY-MM-DD) or Date; always interpret as UTC
  const day = parseUTC(date || new Date());
  const dow = day.getUTCDay(); // 0-6 using UTC

  console.log("🔍 generateDailyOrdersForDate:", {
    ownerId: ownerId.toString(),
    date: day.toISOString(),
    dayOfWeek: dow,
  });

  const subscriptions = await Subscription.find({
    ownerId,
    status: "active",
    startDate: { $lte: day },
    endDate: { $gte: day },
    deliveryDays: { $in: [dow] },
  })
    .populate("planId")
    .lean();

  console.log("📦 Found subscriptions:", subscriptions.length);
  subscriptions.forEach((s) => {
    console.log(
      `  - Sub ${s._id}: days=[${s.deliveryDays}], start=${s.startDate}, end=${s.endDate}`
    );
  });

  if (!subscriptions.length) return 0;

  const existing = await DailyOrder.find({
    ownerId,
    orderDate: day,
    subscriptionId: { $in: subscriptions.map((s) => s._id) },
  })
    .select("subscriptionId")
    .lean();

  console.log("🔁 Existing orders count for date:", existing.length);
  existing.forEach((o) =>
    console.log("  existing subscription", o.subscriptionId)
  );

  const existingSet = new Set(existing.map((d) => d.subscriptionId.toString()));

  const toInsert = [];

  for (const sub of subscriptions) {
    if (existingSet.has(sub._id.toString())) continue;

    const plan = sub.planId;
    const mealType =
      plan?.includesLunch && plan?.includesDinner
        ? "both"
        : plan?.includesDinner
          ? "dinner"
          : "lunch";

    toInsert.push({
      ownerId,
      customerId: sub.customerId,
      subscriptionId: sub._id,
      planId: sub.planId,
      orderDate: day,
      mealType,
      deliverySlot: sub.deliverySlot,
      status: "pending",
    });
  }

  if (!toInsert.length)
    return { generatedCount: 0, existingCount: existing.length };

  await DailyOrder.insertMany(toInsert);
  return { generatedCount: toInsert.length, existingCount: existing.length };
};

export const getTodayDailyOrders = async (ownerId) => {
  const today = parseUTC(new Date());
  return DailyOrder.find({ ownerId, orderDate: today })
    .populate("customerId", "name phone address area")
    .populate("planId", "planName price")
    .populate("deliveryStaffId", "name phone")
    .sort({ createdAt: 1 })
    .lean();
};
