import Delivery from "../models/Delivery.model.js";
import { getTodaysDeliveries } from "../services/delivery.service.js";
import { asyncHandler } from "../utils/asyncHandler.js";
import { ApiResponse } from "../class/apiResponseClass.js";
import { ApiError } from "../class/apiErrorClass.js";

/**
 * GET /api/v1/deliveries/today
 * Returns today's deliveries (creates missing for active subscriptions)
 */
export const getToday = asyncHandler(async (req, res) => {
  const deliveries = await getTodaysDeliveries();

  const response = new ApiResponse(200, "Today's deliveries fetched", {
    data: deliveries,
    total: deliveries.length,
  });

  res.status(response.statusCode).json({
    success: response.success,
    message: response.message,
    data: response.data,
  });
});

/**
 * PUT /api/v1/deliveries/:id/complete
 * Mark delivery as delivered, set completedAt
 */
export const completeDelivery = asyncHandler(async (req, res) => {
  const { id } = req.params;

  const delivery = await Delivery.findById(id);
  if (!delivery) {
    throw new ApiError(404, "Delivery not found");
  }

  if (delivery.status === "delivered") {
    throw new ApiError(400, "Delivery is already completed");
  }

  const now = new Date();
  const updated = await Delivery.findByIdAndUpdate(
    id,
    { $set: { status: "delivered", completedAt: now } },
    { new: true }
  )
    .populate("customerId", "name phone address location")
    .populate("subscriptionId", "planId")
    .populate("deliveryBoyId", "name phone")
    .lean();

  const io = req.app.get("io");
  if (io) {
    io.of("/delivery").to("delivery-today").emit("delivery_updated", updated);
  }

  const response = new ApiResponse(200, "Delivery completed", updated);

  res.status(response.statusCode).json({
    success: response.success,
    message: response.message,
    data: response.data,
  });
});
