import mongoose from "mongoose";

const dailyOrderSchema = new mongoose.Schema(
  {
    ownerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    customerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Customer",
      required: true,
    },
    subscriptionId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Subscription",
    },
    orderId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Order",
    },
    planId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "MealPlan",
    },
    orderDate: {
      type: Date,
      required: true,
    },
    mealType: {
      type: String,
      enum: ["lunch", "dinner", "both"],
      required: true,
    },
    deliverySlot: {
      type: String,
      enum: ["morning", "afternoon", "evening"],
    },
    deliveryStaffId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "DeliveryStaff",
    },
    resolvedItems: [
      {
        name: String,
        quantity: Number,
      },
    ],
    amount: {
      type: Number,
    },
    isCharged: {
      type: Boolean,
      default: false,
    },
    status: {
      type: String,
      enum: [
        "pending",
        "processing",
        "out_for_delivery",
        "delivered",
        "cancelled",
        "failed",
        "skipped",
      ],
      default: "pending",
    },
    cancelledBy: {
      type: String,
      enum: ["customer", "owner", null],
      default: null,
    },
    cancellationReason: {
      type: String,
    },
    cancelledAt: {
      type: Date,
    },
    processedAt: {
      type: Date,
    },
    outForDeliveryAt: {
      type: Date,
    },
    deliveredAt: {
      type: Date,
    },
    deliveryNote: {
      type: String,
    },
    deliveryPhotoUrl: {
      type: String,
    },
    customerRating: {
      type: Number,
      min: 1,
      max: 5,
    },
    customerFeedback: {
      type: String,
    },
    ratedAt: {
      type: Date,
    },
  },
  {
    timestamps: true,
  }
);

dailyOrderSchema.index({ ownerId: 1, orderDate: 1, status: 1 });
dailyOrderSchema.index({ customerId: 1, orderDate: -1 });
dailyOrderSchema.index({ ownerId: 1, orderDate: 1, deliveryStaffId: 1 });

const DailyOrder = mongoose.model("DailyOrder", dailyOrderSchema);

export default DailyOrder;

