import mongoose from "mongoose";

const CUSTOMER_TYPES = ["individual", "corporate", "office"];
const CUSTOMER_STATUSES = ["active", "inactive", "suspended"];

const customerSchema = new mongoose.Schema(
  {
    name: {
      type: String,
      required: true,
      trim: true,
    },
    phone: {
      type: String,
      required: true,
      unique: true,
      trim: true,
    },
    address: {
      type: String,
      default: "",
      trim: true,
    },
    location: {
      type: {
        type: String,
        enum: ["Point"],
        default: "Point",
      },
      coordinates: {
        type: [Number], // [longitude, latitude]
        default: null,
      },
    },
    customerType: {
      type: String,
      enum: CUSTOMER_TYPES,
      default: "individual",
    },
    status: {
      type: String,
      enum: CUSTOMER_STATUSES,
      default: "active",
    },
    fcmToken: {
      type: String,
      default: null,
    },
    whatsapp: {
      type: String,
      default: null,
      trim: true,
    },
    isDeleted: {
      type: Boolean,
      default: false,
    },
  },
  {
    timestamps: true,
  }
);

// customerSchema.index({ phone: 1 }, { unique: true });
customerSchema.index({ status: 1 });
customerSchema.index({ createdAt: -1 });
customerSchema.index({ isDeleted: 1 });

const Customer = mongoose.model("Customer", customerSchema);

export default Customer;
export { CUSTOMER_TYPES, CUSTOMER_STATUSES };
