import DailyOrder from "../models/DailyOrder.model.js";
import { asyncHandler } from "../utils/asyncHandler.js";
import { ApiResponse } from "../class/apiResponseClass.js";
import { ApiError } from "../class/apiErrorClass.js";

const parseUTC = (d) => {
  const date = new Date(d);
  date.setUTCHours(0, 0, 0, 0);
  return date;
};

/**
 * GET /api/v1/delivery/my-deliveries
 * Delivery staff sees their assigned orders for today.
 * Sorted by area for efficient routing.
 */
export const getMyDeliveries = asyncHandler(async (req, res) => {
  const staffId = req.user.staffId;
  if (!staffId) {
    throw new ApiError(
      403,
      "Staff ID not found in token. Please log out and log in again."
    );
  }

  const today = parseUTC(new Date());

  const orders = await DailyOrder.find({
    deliveryStaffId: staffId,
    orderDate: today,
    status: { $nin: ["cancelled", "failed", "skipped"] },
  })
    .populate(
      "customerId",
      "name phone address area landmark location fcmToken"
    )
    .populate("planId", "planName price")
    .populate("resolvedItems.itemId", "name unitPrice unit")
    .sort({ "customerId.area": 1 })
    .lean();

  // Add WhatsApp URL for each customer (click to open chat)
  const enriched = orders.map((order) => {
    const customer = order.customerId;
    const phone = customer?.phone;
    return {
      ...order,
      customerId: customer
        ? {
            ...customer,
            whatsappUrl: phone
              ? `https://wa.me/91${phone.replace(/^\+?91/, "")}`
              : null,
          }
        : null,
    };
  });

  res.status(200).json(
    new ApiResponse(200, "My deliveries fetched", {
      data: enriched,
      total: enriched.length,
      date: today.toISOString().slice(0, 10),
    })
  );
});
