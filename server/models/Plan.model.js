import mongoose from "mongoose";

const PLAN_TYPES = ["regular", "premium", "custom"];
const PLAN_FREQUENCIES = ["daily", "weekly", "monthly", "custom"];

const planSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      trim: true,
    },
    type: {
      type: String,
      enum: PLAN_TYPES,
      default: "regular",
    },
    price: {
      type: Number,
      required: true,
      min: 0,
    },
    frequency: {
      type: String,
      enum: PLAN_FREQUENCIES,
      default: "monthly",
    },
    description: {
      type: String,
      default: "",
      trim: true,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
  },
  {
    timestamps: true,
  }
);

planSchema.index({ isActive: 1 });
planSchema.index({ type: 1 });

const Plan = mongoose.model("Plan", planSchema);

export default Plan;
export { PLAN_TYPES, PLAN_FREQUENCIES };
