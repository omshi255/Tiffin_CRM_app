import DailyOrder from "../models/DailyOrder.model.js";
import Subscription from "../models/Subscription.model.js";
import MealPlan from "../models/Plan.model.js";
import Item from "../models/Item.model.js";

const parseUTC = (d) => {
  if (!d) return new Date();
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
  const date = new Date(d);
  date.setUTCHours(0, 0, 0, 0);
  return date;
};

/**
 * Determine mealType string from the plan's mealSlots.
 * Falls back to includesLunch/includesDinner for legacy plans without mealSlots.
 */
const resolveMealType = (plan) => {
  if (plan.mealSlots && plan.mealSlots.length > 0) {
    const slots = plan.mealSlots.map((s) => s.slot);
    if (slots.length === 1) {
      const s = slots[0];
      if (s === "lunch") return "lunch";
      if (s === "dinner") return "dinner";
      if (s === "breakfast" || s === "early_morning") return "breakfast";
      if (s === "snack") return "snack";
    }
    const hasLunch = slots.includes("lunch");
    const hasDinner = slots.includes("dinner");
    if (hasLunch && hasDinner) return "both";
    return "all";
  }
  // legacy fallback
  if (plan.includesLunch && plan.includesDinner) return "both";
  if (plan.includesDinner) return "dinner";
  return "lunch";
};

/**
 * Build resolvedItems array and compute total amount from plan mealSlots.
 * Fetches item prices from DB in a single query.
 * Returns { resolvedItems, amount }
 */
const buildResolvedItems = async (plan) => {
  if (!plan.mealSlots || plan.mealSlots.length === 0) {
    return { resolvedItems: [], amount: plan.price || 0 };
  }

  // Collect unique itemIds from all slots
  const allItemIds = [
    ...new Set(
      plan.mealSlots.flatMap((slot) =>
        slot.items.map((i) => i.itemId.toString())
      )
    ),
  ];

  if (allItemIds.length === 0) {
    return { resolvedItems: [], amount: 0 };
  }

  // Fetch item prices in one query
  const itemDocs = await Item.find({ _id: { $in: allItemIds } })
    .select("name unitPrice")
    .lean();

  const itemMap = {};
  for (const item of itemDocs) {
    itemMap[item._id.toString()] = item;
  }

  const resolvedItems = [];
  let amount = 0;

  for (const slot of plan.mealSlots) {
    for (const slotItem of slot.items) {
      const itemData = itemMap[slotItem.itemId.toString()];
      if (!itemData) continue; // skip if item was deleted/not found

      const subtotal = slotItem.quantity * itemData.unitPrice;
      resolvedItems.push({
        itemId: slotItem.itemId,
        itemName: itemData.name,
        quantity: slotItem.quantity,
        unitPrice: itemData.unitPrice,
        subtotal,
      });
      amount += subtotal;
    }
  }

  return { resolvedItems, amount };
};

/**
 * Generate DailyOrder records for a given date and owner.
 * Used by POST /subscriptions and the midnight cron.
 */
export const generateDailyOrdersForDate = async (ownerId, date) => {
  const day = parseUTC(date || new Date());
  const dow = day.getUTCDay(); // 0-6 Sunday-Saturday

  console.log("🔍 generateDailyOrdersForDate:", {
    ownerId: ownerId.toString(),
    date: day.toISOString(),
    dayOfWeek: dow,
  });

  // Fetch active + paused subscriptions; paused ones are filtered per-date below
  const subscriptions = await Subscription.find({
    ownerId,
    startDate: { $lte: day },
    endDate: { $gte: day },
    status: { $in: ["active", "paused"] },
    deliveryDays: { $in: [dow] },
  }).lean();

  console.log("📦 Found subscriptions:", subscriptions.length);

  if (!subscriptions.length) return { generatedCount: 0, existingCount: 0 };

  // Skip already-generated orders
  const existing = await DailyOrder.find({
    ownerId,
    orderDate: day,
    subscriptionId: { $in: subscriptions.map((s) => s._id) },
  })
    .select("subscriptionId")
    .lean();

  const existingSet = new Set(existing.map((d) => d.subscriptionId.toString()));

  // Collect unique planIds needed
  const planIds = [
    ...new Set(
      subscriptions
        .filter((s) => !existingSet.has(s._id.toString()))
        .map((s) => s.planId.toString())
    ),
  ];

  // Fetch all plans in one query
  const plans = await MealPlan.find({ _id: { $in: planIds } }).lean();
  const planMap = {};
  for (const plan of plans) {
    planMap[plan._id.toString()] = plan;
  }

  const toInsert = [];

  for (const sub of subscriptions) {
    if (existingSet.has(sub._id.toString())) continue;

    const plan = planMap[sub.planId.toString()];
    if (!plan) {
      console.warn(`⚠️  Plan ${sub.planId} not found for subscription ${sub._id}`);
      continue;
    }

    // Skip paused subscriptions for this date range
    if (
      sub.status === "paused" &&
      sub.pausedFrom &&
      sub.pausedUntil &&
      day >= parseUTC(sub.pausedFrom) &&
      day <= parseUTC(sub.pausedUntil)
    ) {
      console.log(`⏸  Skipping paused subscription ${sub._id} for ${day.toISOString()}`);
      continue;
    }

    const { resolvedItems, amount } = await buildResolvedItems(plan);
    const mealType = resolveMealType(plan);

    toInsert.push({
      ownerId,
      customerId: sub.customerId,
      subscriptionId: sub._id,
      planId: sub.planId,
      orderDate: day,
      mealType,
      deliverySlot: sub.deliverySlot,
      resolvedItems,
      amount,
      status: "pending",
    });
  }

  if (!toInsert.length) {
    return { generatedCount: 0, existingCount: existing.length };
  }

  await DailyOrder.insertMany(toInsert);

  console.log(`✅ Generated ${toInsert.length} orders for ${day.toISOString().slice(0, 10)}`);

  return { generatedCount: toInsert.length, existingCount: existing.length };
};

export const getTodayDailyOrders = async (ownerId) => {
  const today = parseUTC(new Date());
  return DailyOrder.find({ ownerId, orderDate: today })
    .populate("customerId", "name phone address area")
    .populate("planId", "planName price")
    .populate("deliveryStaffId", "name phone")
    .populate("resolvedItems.itemId", "name unitPrice unit")
    .sort({ createdAt: 1 })
    .lean();
};

export const generateOrdersForNextDays = async (ownerId, days = 7) => {
  const results = [];

  // Build dates in UTC to avoid local-midnight / IST timezone footgun.
  const nowUtc = new Date();
  const todayUtc = new Date(
    Date.UTC(nowUtc.getUTCFullYear(), nowUtc.getUTCMonth(), nowUtc.getUTCDate())
  );

  for (let i = 0; i < days; i++) {
    const date = new Date(todayUtc);
    date.setUTCDate(todayUtc.getUTCDate() + i);

    const result = await generateDailyOrdersForDate(ownerId, date);

    results.push({
      date: date.toISOString().slice(0, 10),
      ...result,
    });
  }

  return results;
};
