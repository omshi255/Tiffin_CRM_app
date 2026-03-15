import mongoose from "mongoose";

const SUBSCRIPTION_STATUSES = ["active", "paused", "expired", "cancelled"];

const subscriptionSchema = new mongoose.Schema(
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
    planId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "MealPlan",
      required: true,
    },
    startDate: {
      type: Date,
      required: true,
    },
    endDate: {
      type: Date,
      required: true,
    },
    deliverySlot: {
      type: String,
      enum: ["morning", "afternoon", "evening"],
      default: "morning",
    },
    deliveryDays: {
      type: [Number],
      default: [0, 1, 2, 3, 4, 5, 6], // 0=Sun ... 6=Sat
    },
    status: {
      type: String,
      enum: SUBSCRIPTION_STATUSES,
      default: "active",
    },
    totalAmount: {
      type: Number,
      required: true,
    },
    paidAmount: {
      type: Number,
      default: 0,
    },
    pausedFrom: {
      type: Date,
    },
    pausedUntil: {
      type: Date,
    },
    autoRenew: {
      type: Boolean,
      default: false,
    },
    notes: {
      type: String,
    },
  },
  {
    timestamps: true,
  }
);

subscriptionSchema.index({ ownerId: 1, customerId: 1, status: 1 });
subscriptionSchema.index({ ownerId: 1, endDate: 1 });

const Subscription = mongoose.model("Subscription", subscriptionSchema);

export default Subscription;
export { SUBSCRIPTION_STATUSES };
