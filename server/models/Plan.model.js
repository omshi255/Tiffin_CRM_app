import mongoose from "mongoose";

// MealPlan model as per final spec
const mealPlanSchema = new mongoose.Schema(
  {
    ownerId: {
      type: mongoose.Schema.Types.ObjectId,
      ref: "User",
      required: true,
    },
    planName: {
      type: String,
      required: true,
      trim: true,
    },
    planType: {
      type: String,
      enum: ["daily", "weekly", "monthly", "custom"],
    },
    price: {
      type: Number,
      required: true,
      min: 0,
    },
    includesLunch: {
      type: Boolean,
      default: true,
    },
    includesDinner: {
      type: Boolean,
      default: false,
    },
    menuDescription: {
      type: String,
    },
    isActive: {
      type: Boolean,
      default: true,
    },
    rawMaterials: [
      {
        materialId: {
          type: mongoose.Schema.Types.ObjectId,
          ref: "RawMaterial",
        },
        quantityPerMeal: {
          type: Number,
          required: true,
        },
      },
    ],
    color: {
      type: String,
    },
  },
  {
    timestamps: true,
  }
);

mealPlanSchema.index({ ownerId: 1, isActive: 1 });

// Keep filename/exports but model is MealPlan per spec
const MealPlan = mongoose.model("MealPlan", mealPlanSchema);

export default MealPlan;
