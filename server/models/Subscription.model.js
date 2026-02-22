import mongoose from "mongoose";

const SUBSCRIPTION_STATUSES = ["active", "expired", "cancelled", "pending"];
const BILLING_PERIODS = ["daily", "weekly", "monthly", "custom"];

const subscriptionSchema = new mongoose.Schema(
  {
    customerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Customer",
      required: true,
    },
    planId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Plan",
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
    status: {
      type: String,
      enum: SUBSCRIPTION_STATUSES,
      default: "active",
    },
    billingPeriod: {
      type: String,
      enum: BILLING_PERIODS,
      default: "monthly",
    },
    autoRenew: {
      type: Boolean,
      default: false,
    },
    price: {
      type: Number,
      required: true,
      min: 0,
    },
    paymentId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "Payment",
      default: null,
    },
  },
  {
    timestamps: true,
  }
);

subscriptionSchema.index({ customerId: 1 });
subscriptionSchema.index({ planId: 1 });
subscriptionSchema.index({ status: 1 });
subscriptionSchema.index({ endDate: 1 });

const Subscription = mongoose.model("Subscription", subscriptionSchema);

export default Subscription;
export { SUBSCRIPTION_STATUSES, BILLING_PERIODS };
