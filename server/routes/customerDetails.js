import { Router } from "express";
import crypto from "crypto";
import mongoose from "mongoose";
import Joi from "joi";
import Customer from "../models/Customer.model.js";
import Subscription from "../models/Subscription.model.js";
import Payment from "../models/Payment.model.js";
import Transaction from "../models/Transaction.model.js";
import DeliverySchedule from "../models/DeliverySchedule.model.js";
import DailyOrder from "../models/DailyOrder.model.js";
import User from "../models/User.model.js";
import { authMiddleware } from "../middleware/auth.middleware.js";
import { requireRole } from "../middleware/rbac.middleware.js";
import { asyncHandler } from "../utils/asyncHandler.js";
import { ApiResponse } from "../class/apiResponseClass.js";
import { ApiError } from "../class/apiErrorClass.js";

const router = Router();

/**
 * Public token verification for customer portal magic-link login.
 * GET /api/v1/customer-details/verify-token?token=...&id=...
 */
router.get(
  "/verify-token",
  asyncHandler(async (req, res) => {
    try {
      const token = String(req.query.token || "").trim();
      const id = String(req.query.id || "").trim();
      if (!token || !id || !mongoose.Types.ObjectId.isValid(id)) {
        return res
          .status(401)
          .json({ success: false, message: "Invalid or expired link" });
      }

      const customer = await Customer.findOne({
        _id: id,
        loginToken: token,
        loginTokenExpiry: { $gt: new Date() },
        isDeleted: { $ne: true },
      });

      if (!customer) {
        return res
          .status(401)
          .json({ success: false, message: "Invalid or expired link" });
      }

      const activeSub = await Subscription.findOne({
        customerId: customer._id,
        status: "active",
        endDate: { $gte: new Date() },
      })
        .sort({ endDate: -1 })
        .populate("planId", "planName")
        .lean();

      const planName = activeSub?.planId?.planName || "";

      customer.loginToken = null;
      customer.loginTokenExpiry = null;
      await customer.save();

      return res.status(200).json({
        success: true,
        customer: {
          id: String(customer._id),
          name: customer.name || "",
          phone: customer.phone || "",
          planName,
        },
      });
    } catch (_) {
      return res
        .status(500)
        .json({ success: false, message: "Failed to verify login link" });
    }
  })
);

router.use(authMiddleware);
router.use(requireRole(["vendor", "admin"]));

/** Resolve vendor owner id for scoped queries. */
function resolveOwnerId(req) {
  return req.user.ownerId || req.user.userId;
}

/** Validates Mongo ObjectId string. */
function assertObjectId(id, label = "id") {
  if (!mongoose.Types.ObjectId.isValid(id)) {
    throw new ApiError(400, `Invalid ${label}`);
  }
}

/**
 * Loads the customer for this vendor or throws 404.
 */
async function assertCustomer(ownerId, customerId) {
  assertObjectId(customerId, "customerId");
  const customer = await Customer.findOne({
    _id: customerId,
    ownerId,
    isDeleted: { $ne: true },
  }).lean();
  if (!customer) throw new ApiError(404, "Customer not found");
  return customer;
}

/**
 * Effective wallet total. Uses the higher of legacy `balance` and `walletBalance`
 * so a new `walletBalance` field that was only partially incremented (e.g. 0→50)
 * while `balance` still holds the full ledger (e.g. 6320→6370) never shows as only the top-up.
 */
function effectiveWallet(c) {
  const b = Number(c.balance ?? 0);
  const w = Number(c.walletBalance ?? 0);
  return Math.max(b, w);
}

/** Remaining subscription balance with sane defaults. */
function effectiveRemaining(sub) {
  if (!sub) return 0;
  if (sub.remainingBalance != null) return Number(sub.remainingBalance);
  const total = Number(sub.totalAmount) || 0;
  const paid = Number(sub.paidAmount) || 0;
  return Math.max(0, total - paid);
}

/** Sums meal item quantities across all slots (items per day). */
function countItemsPerDay(plan) {
  if (!plan?.mealSlots?.length) return 0;
  let n = 0;
  for (const slot of plan.mealSlots) {
    for (const it of slot.items || []) {
      n += Number(it.quantity) > 0 ? Number(it.quantity) : 1;
    }
  }
  return n;
}

/** Formats resolved daily order lines into a short label. */
function formatOrderItems(resolvedItems) {
  if (!resolvedItems?.length) return "";
  return resolvedItems
    .map((r) => {
      const name = r.itemName || "Item";
      const q = r.quantity || 1;
      return `${name} x${q}`;
    })
    .join(", ");
}

/** IST calendar date string YYYY-MM-DD for "today" comparisons. */
function istTodayYmd() {
  return new Date().toLocaleDateString("en-CA", { timeZone: "Asia/Kolkata" });
}

/** YYYY-MM-DD in Asia/Kolkata for a stored Date. */
function ymdIST(d) {
  if (!d) return "";
  return new Date(d).toLocaleDateString("en-CA", { timeZone: "Asia/Kolkata" });
}

/** Short label when there are no daily orders yet (plan summary). */
function defaultItemsFromPlan(plan) {
  if (!plan) return "—";
  if (plan.planName) return String(plan.planName);
  return "—";
}

/**
 * GET /api/v1/customer-details/:customerId/info
 * Returns core profile + active plan summary for the Info tab.
 */
router.get(
  "/:customerId/info",
  asyncHandler(async (req, res) => {
    const ownerId = resolveOwnerId(req);
    const { customerId } = req.params;
    const customer = await assertCustomer(ownerId, customerId);

    const sub = await Subscription.findOne({
      ownerId,
      customerId,
      status: "active",
      endDate: { $gte: new Date() },
    })
      .sort({ endDate: -1 })
      .populate("planId")
      .lean();

    let planName = "";
    let startDate = null;
    if (sub?.planId) {
      const p = sub.planId;
      planName = p.planName || "";
      startDate = sub.startDate || null;
    }

    const payload = {
      name: customer.name || "",
      phone: customer.phone || "",
      email: customer.email || "",
      address: customer.address || "",
      planName,
      startDate: startDate ? startDate.toISOString() : "",
      status: customer.status || "active",
    };

    const response = new ApiResponse(200, "Customer info", payload);
    return res.status(response.statusCode).json({
      success: response.success,
      message: response.message,
      data: response.data,
    });
  })
);

/**
 * GET /api/v1/customer-details/:customerId/subscriptions
 * Active plan card + subscription history list.
 */
router.get(
  "/:customerId/subscriptions",
  asyncHandler(async (req, res) => {
    const ownerId = resolveOwnerId(req);
    const { customerId } = req.params;
    await assertCustomer(ownerId, customerId);

    const now = new Date();
    const activeSub = await Subscription.findOne({
      ownerId,
      customerId,
      status: "active",
      endDate: { $gte: now },
    })
      .sort({ endDate: -1 })
      .populate("planId")
      .lean();

    let activePlan = null;
    if (activeSub?.planId) {
      const plan = activeSub.planId;
      const pricePerMonth = Number(plan.price) || 0;
      const itemsPerDay = countItemsPerDay(plan);
      const end = activeSub.endDate ? new Date(activeSub.endDate) : null;
      const start = activeSub.startDate ? new Date(activeSub.startDate) : null;
      let remainingDays = 0;
      if (end) {
        remainingDays = Math.max(
          0,
          Math.ceil((end.getTime() - now.getTime()) / 86400000)
        );
      }
      activePlan = {
        id: activeSub._id.toString(),
        planName: plan.planName || "",
        itemsPerDay,
        pricePerMonth,
        startDate: start ? start.toISOString() : "",
        endDate: end ? end.toISOString() : "",
        remainingDays,
      };
    }

    const historyDocs = await Subscription.find({
      ownerId,
      customerId,
      $or: [{ status: { $ne: "active" } }, { endDate: { $lt: now } }],
    })
      .sort({ endDate: -1 })
      .populate("planId")
      .lean();

    const history = historyDocs.map((h) => {
      const plan = h.planId;
      const planName = plan?.planName || "Plan";
      const end = h.endDate ? new Date(h.endDate) : null;
      const completed = !!end && end.getTime() < now.getTime();
      return {
        planName,
        startDate: h.startDate ? new Date(h.startDate).toISOString() : "",
        endDate: h.endDate ? new Date(h.endDate).toISOString() : "",
        amountPaid: Number(h.paidAmount) || 0,
        completed,
      };
    });

    const response = new ApiResponse(200, "Subscriptions", {
      activePlan,
      history,
    });
    return res.status(response.statusCode).json({
      success: response.success,
      message: response.message,
      data: response.data,
    });
  })
);

/**
 * GET /api/v1/customer-details/:customerId/transactions/:transactionId/receipt
 * Full receipt payload for bottom sheet / share.
 */
router.get(
  "/:customerId/transactions/:transactionId/receipt",
  asyncHandler(async (req, res) => {
    const ownerId = resolveOwnerId(req);
    const { customerId, transactionId } = req.params;
    await assertCustomer(ownerId, customerId);

    const vendor = await User.findById(ownerId).select("businessName ownerName").lean();
    const businessName =
      vendor?.businessName || vendor?.ownerName || "Business";

    if (transactionId.startsWith("pay_")) {
      const pid = transactionId.slice(4);
      assertObjectId(pid, "transactionId");
      const p = await Payment.findOne({
        _id: pid,
        customerId,
        ownerId,
      }).lean();
      if (!p) throw new ApiError(404, "Receipt not found");

      const items = [];
      const total = Number(p.amount) || 0;
      const payload = {
        businessName,
        date: p.paymentDate ? new Date(p.paymentDate).toISOString() : "",
        description: p.notes || (p.type === "wallet_credit" ? "Wallet credit" : "Payment"),
        items,
        total,
        paymentMode: p.paymentMethod || "cash",
        type: p.type === "wallet_credit" ? "credit" : "debit",
      };
      const response = new ApiResponse(200, "Receipt", payload);
      return res.status(response.statusCode).json({
        success: response.success,
        message: response.message,
        data: response.data,
      });
    }

    assertObjectId(transactionId, "transactionId");
    const t = await Transaction.findOne({
      _id: transactionId,
      customerId,
      ownerId,
    }).lean();
    if (!t) throw new ApiError(404, "Receipt not found");

    const items = (t.items || []).map((it) => ({
      name: it.name,
      quantity: it.quantity,
      unitPrice: it.unitPrice,
    }));
    const total = Number(t.amount) || 0;
    const payload = {
      businessName,
      date: t.date ? new Date(t.date).toISOString() : "",
      description: t.description || "",
      items,
      total,
      paymentMode: t.paymentMode || "cash",
      type: t.type,
    };

    const response = new ApiResponse(200, "Receipt", payload);
    return res.status(response.statusCode).json({
      success: response.success,
      message: response.message,
      data: response.data,
    });
  })
);

/**
 * GET /api/v1/customer-details/:customerId/transactions
 * Optional query: startDate, endDate (ISO strings).
 */
router.get(
  "/:customerId/transactions",
  asyncHandler(async (req, res) => {
    const ownerId = resolveOwnerId(req);
    const { customerId } = req.params;
    await assertCustomer(ownerId, customerId);

    const startRaw = req.query.startDate;
    const endRaw = req.query.endDate;
    const start = startRaw ? new Date(String(startRaw)) : new Date(0);
    const end = endRaw ? new Date(String(endRaw)) : new Date(8640000000000000);
    if (Number.isNaN(start.getTime()) || Number.isNaN(end.getTime())) {
      throw new ApiError(400, "Invalid date range");
    }

    const [txns, payments] = await Promise.all([
      Transaction.find({
        ownerId,
        customerId,
        date: { $gte: start, $lte: end },
      })
        .sort({ date: -1 })
        .lean(),
      Payment.find({
        ownerId,
        customerId,
        paymentDate: { $gte: start, $lte: end },
        status: "captured",
      })
        .sort({ paymentDate: -1 })
        .lean(),
    ]);

    const mappedTx = txns.map((t) => ({
      id: t._id.toString(),
      date: t.date ? new Date(t.date).toISOString() : "",
      description: t.description || "",
      amount: Number(t.amount) || 0,
      type: t.type,
      paymentMode: t.paymentMode || "cash",
      items: (t.items || []).map((it) => ({
        name: it.name,
        quantity: it.quantity,
        unitPrice: it.unitPrice,
      })),
    }));

    const mappedPay = payments.map((p) => ({
      id: `pay_${p._id.toString()}`,
      date: p.paymentDate ? new Date(p.paymentDate).toISOString() : "",
      description:
        p.notes ||
        (p.type === "wallet_credit" ? "Wallet credit" : "Payment"),
      amount: Number(p.amount) || 0,
      type: p.type === "wallet_credit" ? "credit" : "debit",
      paymentMode: p.paymentMethod || "cash",
      items: [],
    }));

    const merged = [...mappedTx, ...mappedPay].sort(
      (a, b) => new Date(b.date).getTime() - new Date(a.date).getTime()
    );

    const response = new ApiResponse(200, "Transactions", merged);
    return res.status(response.statusCode).json({
      success: response.success,
      message: response.message,
      data: response.data,
    });
  })
);

/**
 * GET /api/v1/customer-details/:customerId/balance
 */
router.get(
  "/:customerId/balance",
  asyncHandler(async (req, res) => {
    const ownerId = resolveOwnerId(req);
    const { customerId } = req.params;
    const customer = await assertCustomer(ownerId, customerId);

    const sub = await Subscription.findOne({
      ownerId,
      customerId,
      status: "active",
      endDate: { $gte: new Date() },
    })
      .sort({ endDate: -1 })
      .lean();

    const subBal = effectiveRemaining(sub);

    const payload = {
      walletBalance: effectiveWallet(customer),
      subscriptionBalance: subBal,
    };

    const response = new ApiResponse(200, "Balance", payload);
    return res.status(response.statusCode).json({
      success: response.success,
      message: response.message,
      data: response.data,
    });
  })
);

const addBalanceSchema = Joi.object({
  amount: Joi.number().positive().required(),
  paymentMode: Joi.string().valid("cash", "upi", "online").required(),
  note: Joi.string().allow("").optional(),
});

/**
 * POST /api/v1/customer-details/:customerId/add-balance
 * Increments wallet balance and records a credit transaction.
 */
router.post(
  "/:customerId/add-balance",
  asyncHandler(async (req, res) => {
    const ownerId = resolveOwnerId(req);
    const { customerId } = req.params;
    const { error, value } = addBalanceSchema.validate(req.body, {
      stripUnknown: true,
    });
    if (error) {
      throw new ApiError(400, error.details.map((d) => d.message).join("; "));
    }
    await assertCustomer(ownerId, customerId);

    const modeMap = { cash: "cash", upi: "upi", online: "razorpay" };
    const storedMode = modeMap[value.paymentMode] || "cash";

    const session = await mongoose.startSession();
    session.startTransaction();
    try {
      const inc = Number(value.amount);
      const updated = await Customer.findByIdAndUpdate(
        customerId,
        {
          $inc: { walletBalance: inc, balance: inc },
        },
        { new: true, session }
      ).lean();

      await Transaction.create(
        [
          {
            ownerId,
            customerId,
            date: new Date(),
            description: value.note || "Wallet top-up",
            amount: inc,
            type: "credit",
            paymentMode: storedMode,
            source: "wallet_topup",
            items: [],
          },
        ],
        { session }
      );

      await session.commitTransaction();
      session.endSession();

      const subAfter = await Subscription.findOne({
        ownerId,
        customerId,
        status: "active",
        endDate: { $gte: new Date() },
      })
        .sort({ endDate: -1 })
        .lean();

      const response = new ApiResponse(200, "Balance added", {
        success: true,
        updatedWalletBalance: effectiveWallet(updated),
        updatedSubscriptionBalance: effectiveRemaining(subAfter),
      });
      return res.status(response.statusCode).json({
        success: response.success,
        message: response.message,
        data: response.data,
      });
    } catch (e) {
      await session.abortTransaction();
      session.endSession();
      throw e;
    }
  })
);

const extraChargeSchema = Joi.object({
  amount: Joi.number().positive().required(),
  note: Joi.string().trim().required(),
  chargeType: Joi.string().valid("separate", "subscription").required(),
});

/**
 * POST /api/v1/customer-details/:customerId/send-login-link
 * Generates one-time login token (24h) and returns WhatsApp-ready message.
 */
router.post(
  "/:customerId/send-login-link",
  asyncHandler(async (req, res) => {
    try {
      const ownerId = resolveOwnerId(req);
      const { customerId } = req.params;
      const customer = await Customer.findOne({
        _id: customerId,
        ownerId,
        isDeleted: { $ne: true },
      });
      if (!customer) {
        return res
          .status(404)
          .json({ success: false, message: "Customer not found" });
      }

      const token = crypto.randomBytes(32).toString("hex");
      const expiry = new Date(Date.now() + 24 * 60 * 60 * 1000);
      customer.loginToken = token;
      customer.loginTokenExpiry = expiry;
      await customer.save();

      const basePortal = process.env.CUSTOMER_PORTAL_URL || "";
      const loginUrl = `${basePortal}/login?token=${token}&id=${customer._id}`;

      const message =
        `Hello ${customer.name}!\n\n` +
        "Here is your login link for the customer portal:\n\n" +
        `${loginUrl}\n\n` +
        "This link is valid for 24 hours.\n\n" +
        "Thank you!";

      return res.status(200).json({
        success: true,
        loginUrl,
        phone: customer.phone || "",
        message,
      });
    } catch (_) {
      return res
        .status(500)
        .json({ success: false, message: "Could not create login link" });
    }
  })
);

/**
 * POST /api/v1/customer-details/:customerId/extra-charge
 */
router.post(
  "/:customerId/extra-charge",
  asyncHandler(async (req, res) => {
    const ownerId = resolveOwnerId(req);
    const { customerId } = req.params;
    const { error, value } = extraChargeSchema.validate(req.body, {
      stripUnknown: true,
    });
    if (error) {
      throw new ApiError(400, error.details.map((d) => d.message).join("; "));
    }
    await assertCustomer(ownerId, customerId);

    const amt = Number(value.amount);

    const session = await mongoose.startSession();
    session.startTransaction();
    try {
      if (value.chargeType === "separate") {
        await Customer.findByIdAndUpdate(
          customerId,
          { $inc: { pendingDue: amt } },
          { session }
        );
        await Transaction.create(
          [
            {
              ownerId,
              customerId,
              date: new Date(),
              description: value.note,
              amount: amt,
              type: "debit",
              paymentMode: "cash",
              source: "extra_charge_separate",
              items: [
                {
                  name: value.note,
                  quantity: 1,
                  unitPrice: amt,
                },
              ],
            },
          ],
          { session }
        );
      } else {
        const sub = await Subscription.findOne({
          ownerId,
          customerId,
          status: "active",
          endDate: { $gte: new Date() },
        })
          .sort({ endDate: -1 })
          .session(session)
          .exec();

        if (!sub) {
          throw new ApiError(400, "No active subscription to deduct from");
        }
        const cur = effectiveRemaining(sub.toObject ? sub.toObject() : sub);
        if (cur < amt) {
          throw new ApiError(400, "Insufficient subscription balance");
        }
        await Subscription.findByIdAndUpdate(
          sub._id,
          { $inc: { remainingBalance: -amt } },
          { session }
        );
        await Transaction.create(
          [
            {
              ownerId,
              customerId,
              date: new Date(),
              description: value.note,
              amount: amt,
              type: "debit",
              paymentMode: "cash",
              source: "extra_charge_subscription",
              items: [
                {
                  name: value.note,
                  quantity: 1,
                  unitPrice: amt,
                },
              ],
            },
          ],
          { session }
        );
      }

      const customer = await Customer.findById(customerId).session(session).lean();
      const subAfter = await Subscription.findOne({
        ownerId,
        customerId,
        status: "active",
        endDate: { $gte: new Date() },
      })
        .sort({ endDate: -1 })
        .session(session)
        .lean();

      await session.commitTransaction();
      session.endSession();

      const response = new ApiResponse(200, "Charge recorded", {
        success: true,
        updatedWalletBalance: effectiveWallet(customer),
        updatedSubscriptionBalance: effectiveRemaining(subAfter),
      });
      return res.status(response.statusCode).json({
        success: response.success,
        message: response.message,
        data: response.data,
      });
    } catch (e) {
      await session.abortTransaction();
      session.endSession();
      throw e;
    }
  })
);

/**
 * GET /api/v1/customer-details/:customerId/deliveries
 * Full subscription window: one row per calendar day from startDate → endDate (IST).
 */
router.get(
  "/:customerId/deliveries",
  asyncHandler(async (req, res) => {
    const ownerId = resolveOwnerId(req);
    const { customerId } = req.params;
    await assertCustomer(ownerId, customerId);

    const subscription = await Subscription.findOne({
      ownerId,
      customerId,
      status: "active",
      endDate: { $gte: new Date() },
    })
      .sort({ endDate: -1 })
      .populate("planId")
      .lean();

    if (!subscription) {
      const empty = new ApiResponse(200, "Deliveries", {
        subscription: null,
        deliveries: [],
      });
      return res.status(empty.statusCode).json({
        success: empty.success,
        message: empty.message,
        data: empty.data,
      });
    }

    const plan = subscription.planId;
    const planName = plan?.planName ? String(plan.planName) : "";

    const startYmd = ymdIST(subscription.startDate);
    const endYmd = ymdIST(subscription.endDate);
    const startMs = new Date(`${startYmd}T00:00:00+05:30`).getTime();
    const endMs = new Date(`${endYmd}T00:00:00+05:30`).getTime();
    const dayMs = 86400000;
    const totalDays =
      startMs > endMs
        ? 0
        : Math.floor((endMs - startMs) / dayMs) + 1;

    const todayYmd = istTodayYmd();
    const todayMs = new Date(`${todayYmd}T00:00:00+05:30`).getTime();
    const remStartMs = Math.max(startMs, todayMs);
    let remainingDays = 0;
    if (remStartMs <= endMs) {
      for (let t = remStartMs; t <= endMs; t += dayMs) {
        remainingDays += 1;
      }
    }

    const rangeStart = new Date(`${startYmd}T00:00:00+05:30`);
    const rangeEnd = new Date(`${endYmd}T23:59:59.999+05:30`);

    const [scheduleDocs, orderDocs] = await Promise.all([
      DeliverySchedule.find({
        ownerId,
        customerId,
        date: { $gte: rangeStart, $lte: rangeEnd },
      }).lean(),
      DailyOrder.find({
        ownerId,
        customerId,
        orderDate: { $gte: rangeStart, $lte: rangeEnd },
      }).lean(),
    ]);

    const scheduleByYmd = new Map();
    for (const s of scheduleDocs) {
      scheduleByYmd.set(ymdIST(s.date), s);
    }

    const ordersByYmd = new Map();
    for (const o of orderDocs) {
      const k = ymdIST(o.orderDate);
      if (!ordersByYmd.has(k)) ordersByYmd.set(k, []);
      ordersByYmd.get(k).push(o);
    }

    const startDateObj = subscription.startDate
      ? new Date(subscription.startDate)
      : null;
    const endDateObj = subscription.endDate
      ? new Date(subscription.endDate)
      : null;

    const rows = [];
    for (let t = startMs; t <= endMs; t += dayMs) {
      const ymd = new Date(t).toLocaleDateString("en-CA", {
        timeZone: "Asia/Kolkata",
      });

      const schedule = scheduleByYmd.get(ymd);
      const orders = ordersByYmd.get(ymd) || [];

      let items = "";
      let status = "pending";

      if (schedule?.status === "cancelled") {
        items =
          schedule.items ||
          formatOrderItems(orders.flatMap((o) => o.resolvedItems || []));
        status = "cancelled";
      } else if (orders.length) {
        items = formatOrderItems(orders.flatMap((o) => o.resolvedItems || []));
        const hasDelivered = orders.some((o) => o.status === "delivered");
        const hasCancelled = orders.some((o) => o.status === "cancelled");
        if (hasCancelled && !hasDelivered) status = "cancelled";
        else if (hasDelivered) status = "delivered";
        else status = "pending";
      } else {
        items = defaultItemsFromPlan(plan);
        status = "pending";
      }

      rows.push({
        date: ymd,
        items: items || "—",
        status,
      });
    }

    const subPayload = {
      planName,
      startDate: startDateObj ? startDateObj.toISOString() : "",
      endDate: endDateObj ? endDateObj.toISOString() : "",
      totalDays,
      remainingDays,
    };

    const response = new ApiResponse(200, "Deliveries", {
      subscription: subPayload,
      deliveries: rows,
    });
    return res.status(response.statusCode).json({
      success: response.success,
      message: response.message,
      data: response.data,
    });
  })
);

/**
 * PATCH /api/v1/customer-details/:customerId/deliveries/:date/cancel
 * date = YYYY-MM-DD
 */
router.patch(
  "/:customerId/deliveries/:date/cancel",
  asyncHandler(async (req, res) => {
    const ownerId = resolveOwnerId(req);
    const { customerId, date } = req.params;
    await assertCustomer(ownerId, customerId);

    const ymd = String(date);
    if (!/^\d{4}-\d{2}-\d{2}$/.test(ymd)) {
      throw new ApiError(400, "Invalid date");
    }

    const today = istTodayYmd();
    if (ymd < today) {
      throw new ApiError(400, "Cannot cancel past deliveries");
    }

    const start = new Date(`${ymd}T00:00:00+05:30`);
    const end = new Date(`${ymd}T23:59:59.999+05:30`);

    const orders = await DailyOrder.find({
      ownerId,
      customerId,
      orderDate: { $gte: start, $lte: end },
    }).lean();

    const itemsText = formatOrderItems(orders.flatMap((o) => o.resolvedItems || []));

    await DeliverySchedule.findOneAndUpdate(
      { customerId, date: { $gte: start, $lte: end } },
      {
        $set: {
          ownerId,
          customerId,
          date: start,
          items: itemsText,
          status: "cancelled",
          cancelledAt: new Date(),
        },
      },
      { upsert: true, new: true }
    );

    await DailyOrder.updateMany(
      {
        ownerId,
        customerId,
        orderDate: { $gte: start, $lte: end },
        status: { $nin: ["delivered", "cancelled"] },
      },
      {
        $set: {
          status: "cancelled",
          cancelledAt: new Date(),
          cancelledBy: "customer",
        },
      }
    );

    const io = req.app.get("io");
    if (io) {
      const vendorRoomId = resolveOwnerId(req);
      io.of("/delivery")
        .to(`admin:${vendorRoomId}`)
        .emit("daily_orders_changed", {
          date: ymd,
          customerId: String(customerId),
        });
    }

    const response = new ApiResponse(200, "Delivery cancelled", {
      success: true,
      date: ymd,
      status: "cancelled",
    });
    return res.status(response.statusCode).json({
      success: response.success,
      message: response.message,
      data: response.data,
    });
  })
);

export default router;
